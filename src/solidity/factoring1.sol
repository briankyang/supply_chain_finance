pragma solidity ^0.4.11;

contract Factoring { //保理,收购应付账款,根据资信数据提供融资
    address private owner; //合约所有人

    struct Financing { //所获融资
        uint256 amount; //每次获得融资数
        uint256 time; //获得融资时间
    }

    struct Debt { //应收账款
        address exporter; //记录出口商， 实现账款可追溯性 20
        uint256 unpaid_amount; //未付清数额 8
        uint256 paid_amount; //付清数额 8
        uint256 time; //期限 8
    }

    struct Queue { //用于确定融资，出口商和进口商都明确向保理提出应收账款转移后，保理才可以向出口商进行放款融资，并记录与出口商的账款
        address exporter; //出口商 20字节
        address merchant; //进口商 20字节
        uint256 amount; //应收账款额度 8字节
        uint256 current_credit; //当前该进口商的信用额度 8字节
        uint256 time; //应收账款的期限 8字节
        bool status; //1字节
    }

    mapping (address=>uint256) private credit; //资信数据  0000 ~ 10000 : 0% ~ 100%

    mapping (address=>Financing[]) private giving_history; //融资记录
    
    mapping (address=>Debt[]) private receiving_history; //应收账款记录

    mapping (address=>uint256) private refund; //多余的还款以及放款

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

    constructor() payable public {
        owner = msg.sender; //记录创建此合约的地址 
    }

    function getQueue() view public returns(byte[] data) {
        data = new byte[](queue.length * 65);
        uint idx = 0;
        uint j = 0;
        for (uint i = 0; i < queue.length; i++){
            for (j = 0; j < 20; ++j)
                data[idx++] = bytes20(queue[i].exporter)[j];
            for (j = 0; j < 20; ++j)
                data[idx++] = bytes20(queue[i].merchant)[j];
            for (j = 0; j < 8; ++j)
                data[idx++] = bytes8(queue[i].amount)[j];
            for (j = 0; j < 8; ++j)
                data[idx++] = bytes8(queue[i].current_credit)[j];
            for (j = 0; j < 8; ++j)
                data[idx++] = bytes8(queue[i].time)[j];
            data[idx++] = queue[i].status ? byte(1) : byte(0);
        }
    }

    function getDebts(address merchant) check_permission view public returns(byte[] data) {
        data = new byte[](receiving_history[merchant].length * 44);
        uint idx = 0;
        uint j;
        for (uint i = 0;i < receiving_history[merchant].length; ++i){
            for (j = 0; j < 20; ++j)
                data[idx++] = bytes8(receiving_history[merchant][i].exporter)[j];
            for (j = 0; j < 8; ++j)
                data[idx++] = bytes8(receiving_history[merchant][i].unpaid_amount)[j];
            for (j = 0; j < 8; ++j)
                data[idx++] = bytes8(receiving_history[merchant][i].paid_amount)[j];
            for (j = 0; j < 8; ++j)
                data[idx++] = bytes8(receiving_history[merchant][i].time)[j];
        }

    }

    function getCredit(address _merchant) check_permission view public returns(uint _credit) {
        _credit = credit[_merchant];
    }

    function setCredit(address _address, uint256 _value) check_permission public returns(bool) { //调整资信数据
        require(_value <= 10000 && _value >= 0);
        credit[_address] = _value;
        return true;
    }

    function requestFinancing(address _merchant, uint256 _amount, uint256 _time)
    check_repeat(msg.sender, _merchant) public returns(uint256 cash) { //请求融资,并返回融资占应收账款的百分比
        require(_time > now); //应收账款不能是坏账
        if (credit[_merchant] == 0) credit[_merchant] = 7500; //默认75%
        queue.push(Queue(msg.sender, _merchant, _amount, credit[_merchant], _time, true));
        cash = credit[_merchant] * _amount / 10000; //返回可以获得融资数额
    }

    function cancelFinancing(address _merchant, uint256 _amount, uint256 _time) public returns(bool status){ //当出口商觉得融资比例不足或其他原因时，向保理提出取消融资申请
        status = false;
        for (uint i = 0; i < queue.length; ++i){ //查找融资申请并取消之
            if (queue[i].exporter == msg.sender && queue[i].merchant == _merchant && 
            queue[i].amount == _amount && queue[i].time == _time){ //找到该融资请求记录
                queue[i].status = false;
                status = true;
                break;
            }
        }
    }

    function commitTransferDebt(address _exporter, uint256 _amount, uint256 _time) public
     returns(bool status) { //进口商向保理发起确定，确定成功后进行应收账款转让，并且保理向出口商进行融资房款
        status = false;
        for (uint i = 0; i < queue.length; ++i){
            if (queue[i].exporter == _exporter && queue[i].merchant == msg.sender &&
             queue[i].amount == _amount && queue[i].time == _time){ //判断信息是否与进口商提供的一致
                // 评分并融资,且进行各项记录，包括应收账款信息
                receiving_history[msg.sender].push(Debt(_exporter, _amount, 0, _time)); //记账
                uint256 cash = queue[i].current_credit * _amount / 10000;
                giving_history[_exporter].push(Financing(cash, now)); //记录融资情况
                refund[_exporter] += cash; //放款
                queue[i].status = false;
                status = true;
                break; //跳出循环
            }
        }
    }

    function payBack(address _exporter, uint256 _time) payable public returns(bool is_remainder) { //还款
        is_remainder = false;
        uint amount = msg.value;
        credit[msg.sender] = credit[msg.sender] == 0 ? 7500 : credit[msg.sender];
        credit[_exporter] = credit[_exporter] == 0 ? 7500 : credit[_exporter];
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

    function get_money(uint256 _amount) public returns(bool status){ //取钱
        status = false;
        uint amount = refund[msg.sender]; //查询该账户目前可以提取的额度
        if (amount < _amount || amount <= 0) return;
        refund[msg.sender] -= _amount; //减少可提取额度
        msg.sender.transfer(_amount); //转账
    }

    function get_amount() view public returns(uint256) {
        return refund[msg.sender];
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