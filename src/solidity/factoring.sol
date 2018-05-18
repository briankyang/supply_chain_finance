pragma solidity ^0.4.11;

contract Factoring { //保理,收购应付账款,根据资信数据提供融资
    address private owner; //合约所有人

    struct Financing { //所获融资
        uint256 amount; //每次获得融资数
        uint time; //获得融资时间
    }

    struct Debt { //应收账款
        uint256 unpaid_amount; //未付清数额
        uint256 paid_amount; //付清数额
        address exporter; //记录出口商， 实现账款可追溯性
        uint time; //期限
    }

    struct Queue { //用于确定融资，出口商和进口商都明确向保理提出应收账款转移后，保理才可以向出口商进行放款融资，并记录与出口商的账款
        address exporter; //出口商
        address merchant; //进口商
        uint amount; //应收账款额度
        uint current_credit; //当前该进口商的信用额度
        uint time; //应收账款的期限
    }

    mapping (address=>uint256) private credit; //资信数据  0000 ~ 10000 : 0% ~ 100%

    mapping (address=>Financing[]) private giving_history; //融资记录
    
    mapping (address=>Debt[]) private receiving_history; //应收账款记录

    mapping (address=>uint) private refund; //多余的还款以及放款

    Queue[] private queue; //申请融资的队列

    modifier check_permission() { //授权检查， 用来检查是否为保理本人/机构操作
        require(msg.sender == owner);
        _;
    }

    modifier check_repeat(address _exporter, address _merchant) { //检查队列中是否有已经在进行中的融资活动
        for (uint i = 0; i < queue.length; ++i)
            if (queue[i].exporter == _exporter && queue[i].merchant == _merchant) revert(); //若有已经存在的融资行为则回滚操作
        _;
    }

    function Factoring() payable public {
        owner = msg.sender; //记录创建此合约的地址 
    }

    function getQueue() view public returns(uint256[] record) {
        record = new uint256[](queue.length * 3);
        uint idx = 0;
        for (uint i = 0; i < queue.length; ++i){
            record[idx++] = queue[i].amount;
            record[idx++] = queue[i].current_credit;
            record[idx++] = queue[i].time;
        }
    }

    function get_credit(address _address) check_permission view public returns(uint _credit) {
        _credit = credit[_address];
    }

    function adjust_credit(address _address, uint256 _value) check_permission public { //调整资信数据
        require(_value <= 10000 && _value >= 0);
        credit[_address] = _value;
    }

    function request_financing(address _merchant, uint _amount, uint _time) check_repeat(msg.sender, _merchant) public returns(uint cash) { //请求融资,并返回融资占应收账款的百分比
        require(_time > now); //应收账款不能是坏账
        if (credit[_merchant] == 0) credit[_merchant] = 7500; //默认75%
        queue.push(Queue(msg.sender, _merchant, _amount, credit[_merchant], _time));
        cash = credit[_merchant] * _amount / 10000; //返回可以获得融资数额
    }

    function cancel_financing(address _merchant, uint _amount, uint _time) public returns(bool status){ //当出口商觉得融资比例不足或其他原因时，向保理提出取消融资申请
        status = false;
        for (uint i = 0; i < queue.length; ++i){ //查找融资申请并取消之
            if (queue[i].exporter == msg.sender && queue[i].merchant == _merchant && queue[i].amount == _amount && queue[i].time == _time){ //找到该融资请求记录
                delete_queue_element(i); //删除队列中的申请记录
                status = true;
                // break;
            }
        }
    }

    function commit_transfer_debt(address _exporter, uint _amount, uint _time) public returns(bool status) { //进口商向保理发起确定，确定成功后进行应收账款转让，并且保理向出口商进行融资房款
        status = false;
        for (uint i = 0; i < queue.length; ++i){
            if (queue[i].exporter == _exporter && queue[i].merchant == msg.sender && queue[i].amount == _amount && queue[i].time == _time){ //判断信息是否与进口商提供的一致
                delete_queue_element(i);
                // 评分并融资,且进行各项记录，包括应收账款信息
                receiving_history[msg.sender].push(Debt(_amount, 0, _exporter, _time)); //记账
                uint cash = queue[i].current_credit * _amount / 10000;
                giving_history[_exporter].push(Financing(cash, now)); //记录融资情况
                refund[_exporter] += cash; //放款
                status = true;
                break; //跳出循环
            }
        }
    }

    function pay_back(address _exporter, uint _time) payable public returns(bool is_remainder) { //还款
        is_remainder = false;
        uint amount = msg.value;
        Debt[] storage debt = receiving_history[msg.sender];
        for (uint i = 0; i < debt.length; ++i){
            if (debt[i].time == _time && amount > 0 && debt[i].unpaid_amount > 0 && debt[i].exporter == _exporter){//偿还应收账款的信息，包括期限以及前持有人
                if (debt[i].unpaid_amount <= amount){ //可以还清一笔账款
                    uint unpaid = debt[i].unpaid_amount;
                    debt[i].unpaid_amount = 0;
                    debt[i].paid_amount += unpaid;
                    amount -= unpaid;
                    if (credit[msg.sender] < 9000) { //当还清一笔账款时候进行信用调整
                        if(now <= _time) {//偿还时间前于期限者增加额度
                            credit[msg.sender] += credit[msg.sender] / 2; //进口商增加信用额度
                            credit[debt[i].exporter] += credit[debt[i].exporter] / 2; //为出口商增加信用额度
                        }
                        if (now - _time > 7 days) {//超期还款减额度
                            credit[msg.sender] -= 1000; //进口商信用额度减少10%
                            credit[debt[i].exporter] -= 1000; //出口商也会受到牵连
                        }
                        credit[msg.sender] = credit[msg.sender] > 9000 ? 9000 : credit[msg.sender]; //调整信用额度，使其不超过90%
                        credit[debt[i].exporter] = credit[debt[i].exporter] > 9000 ? 9000 : credit[debt[i].exporter];
                    }
                }else { //还不清一笔账款
                    debt[i].unpaid_amount -= amount;
                    debt[i].paid_amount += amount;
                    amount = 0;
                }
            }
        }
        if (amount > 0) {
            refund[msg.sender] += amount;
            is_remainder = true; //如果有剩余，则通知让进口商提钱
        }
    }


    function get_money(uint _amount) public returns(bool status){ //取钱
        status = false;
        uint amount = refund[msg.sender]; //查询该账户目前可以提取的额度
        if (amount < _amount || amount <= 0) return;
        refund[msg.sender] -= _amount; //减少可提取额度
        msg.sender.transfer(_amount); //转账
    }

    function delete_queue_element(uint idx) private { //删除队列中指定下标项
        require(idx < queue.length);
        for (uint i = idx; i < queue.length; ++i) {
            queue[i] = queue[i + 1];
        }
        delete queue[queue.length - 1];
        queue.length--;
    }

}