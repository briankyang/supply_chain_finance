pragma solidity ^0.4.11;

contract Factoring { //保理接口
    function request_financing(address _merchant, uint _amount, uint _time) public returns(uint); //请求融资
    function cancel_financing(address _merchant, uint _amount, uint _time) public returns(bool); //取消融资请求
    function commit_transfer_debt(address _exporter, uint _amount, uint _time) public returns(bool); //确认转移应收账款
    function pay_back(address _exporter, uint _time) payable public returns(bool); //还钱
    function get_money(uint amount) public returns(bool); //提钱
}

contract Enterprise {
    address private owner; //合约持有人

    struct Debt{ //债务
        uint256 amount; //金额
        bool debt_type; // 类型， true表示欠债， false表示应收账款
        bool is_transferred; //表示是否已转移
        address owner; //用来记录欠债的前属主或转移的保理地址
        uint time; //应还时间
        bool status;
    }

    struct Financing { //记录所获融资
        uint256 amount; //应收账款额
        uint256 cash; //可以获得融资额
        bool is_done; //是否已到帐
    }

    struct Record {
        address factoring;
        Debt debt;
        uint cash;
        bool status; //是否有效
    }

    mapping (address=>Debt[]) private debt_records; //记录债务，囊括欠债和应收账款
    mapping (address=>Financing[]) private financing_records; //融资记录

    Record[] private records;
    Record[] private need_commit_records;

    modifier check_permission() { //权限检查
        require(msg.sender == owner);
        _;
    }

    function Enterprise() payable public {
        owner = msg.sender;
    }

    //TODO 返回记录详情
    function getDebts(address someone) view check_permission public returns(uint256[] record){
        Debt[] storage debts = debt_records[someone];
        record = new uint256[](debts.length * 4);
        uint idx = 0;
        for (uint i = 0; i < debts.length; ++i){
            record[idx++] = debts[i].amount;
            record[idx++] = debts[i].debt_type == true ? 1 : 0;
            record[idx++] = debts[i].is_transferred ? 1 : 0;
            record[idx++] = debts[i].time;
        }
    }

    function getFinancing(address someone) view check_permission public returns(uint256[] record) {
        Financing[] storage financing = financing_records[someone];
        record = new uint256[](financing.length * 3);
        uint idx = 0;
        for (uint i = 0; i < financing.length; ++i){
            record[idx++] = financing[i].amount;
            record[idx++] = financing[i].cash;
            record[idx++] = financing[i].is_done ? 1 : 0;
        }
    }

    function getRecords() view check_permission public returns (uint256[] record){
        // Financing[] storage financing = financing_records[someone];
        record = new uint256[](records.length * 3);
        uint idx = 0;
        for (uint i = 0; i < records.length; ++i){
            record[idx++] = records[i].debt.amount;
            record[idx++] = records[i].debt.time;
            record[idx++] = records[i].cash;
        }
    }

    function getNeedCommitRecords() view check_permission public returns (uint256[] record){
        // Financing[] storage financing = financing_records[someone];
        record = new uint256[](need_commit_records.length * 3);
        uint idx = 0;
        for (uint i = 0; i < need_commit_records.length; ++i){
            record[idx++] = need_commit_records[i].debt.amount;
            record[idx++] = need_commit_records[i].debt.time;
            record[idx++] = need_commit_records[i].cash;
        }
    }

    function financing(address _factor, address _merchant, uint _amount, uint _time) check_permission public returns(uint cash) {
        cash = 0;
        Debt[] storage debts = debt_records[_merchant];
        uint idx = 0;
        for (; idx < debts.length; ++idx){ //寻找该债务记录
            if (!debts[idx].is_transferred && debts[idx].debt_type == false && debts[idx].amount == _amount && debts[idx].time == _time) break; //找到记录了
        }
        if(idx >= debts.length) return;//检查是否存在该项账款， 如果不存在则不进行后面的操作
        // require(idx < debts.length); 
        Factoring factoring = Factoring(_factor); //保理
        cash = factoring.request_financing(_merchant, _amount, _time); //获取可融资额度
        records.push(Record(_factor, debts[idx],cash,true));
        //Enterprise enterprise = Enterprise(_merchant); //进口商
        // if (_required <= cash/* && enterprise.transfer_debt(_factor, _amount, _time)*/) { //如果融资额在可接受范围内并且进口商转移应收账款成功，则通知进口商进行账款转移
            // debts[idx].is_transferred = true; //记录已转移
            // debts[idx].owner = _factor; //记录转移的保理地址
            //if(!get_money_from_factor(_factor, cash)) {
            //    status = false;
                // revert(); //如果没有成功进行融资， 则回退所有操作
            //}else
            //    status = true;
        // }else {
            //factoring.cancel_financing(_merchant, _amount, _time); //取消融资请求
        // }
    }

    function commit_finanicing(address _factor, address _merchant, uint _amount, uint _time) check_permission public returns(bool status) {
        status = false;
        uint idx = 0;
        for(;idx < records.length; idx++){
            if (records[idx].factoring != _factor) continue;
            if (records[idx].debt.owner == _merchant && records[idx].debt.amount == _amount && records[idx].debt.time == _time) break;
        }
        if (idx >= records.length) return;
        Enterprise ee = Enterprise(_merchant);
        status = ee.transfer_debt(_factor, _amount, _time);
        // if (status){
        //     records[idx].debt.is_transferred = true;
        //     records[idx].debt.owner = _factor;
        //     delete_record(records, idx);
        // }
    }

    function cancel_finanicing(address _factor, address _merchant, uint _amount, uint _time) check_permission public returns (bool status) {
        status = false;
        uint idx = 0;
        for(;idx < records.length; idx++){
            if (records[idx].factoring != _factor) continue;
            if (records[idx].debt.owner == _merchant && records[idx].debt.amount == _amount && records[idx].debt.time == _time) break;
        }
        if (idx >= records.length) return;
        Factoring fto = Factoring(_factor);
        status = fto.cancel_financing(_merchant, _amount, _time);
        if (status == true){
            delete_record(records, idx);
        }
    }

    function transfer_debt(address _factor,uint _amount, uint _time) public returns(bool status) { //转移账款信息
        status = false;
        Debt[] storage debts = debt_records[msg.sender];
        uint idx = 0;
        for (; idx < debts.length; ++idx){ //找到这一笔账款
            if (debts[idx].debt_type == true && debts[idx].amount == _amount && debts[idx].time == _time) break;
        }
        if (idx >= debts.length) return;
        need_commit_records.push(Record(_factor, debts[idx], debts[idx].amount, true));
        status = true;
        // Factoring factoring = Factoring(_factor);
        // if (factoring.commit_transfer_debet(msg.sender, _amount, _time)){ //如果确认成功则进行相应的记账操作
            // status = true;
            // debt_records[_factor].push(Debt(debts[idx].amount, true, true, msg.sender, _time)); //记录
            // delete_debt(debts, idx); //删除债务信息
        // }
    }

    function commit_transfer_debt(address _factor, address _exporter, uint _amount, uint _time) check_permission public returns(bool status) {
        status = false;
        uint idx = 0;
        for (; idx < need_commit_records.length; idx++){
            if (need_commit_records[idx].factoring != _factor) continue;
            if (need_commit_records[idx].debt.owner == _exporter && need_commit_records[idx].debt.amount == _amount && need_commit_records[idx].debt.time == _time) break;
        }
        if (idx >= need_commit_records.length) return;
        Factoring fto = Factoring(_factor);
        status = fto.commit_transfer_debt(_exporter, _amount, _time);
        if (status){
            debt_records[_factor].push(Debt(need_commit_records[idx].debt.amount, true, true, _exporter, _time, true)); //记录
            // for (uint i = 0; i < debt_records[_exporter].length; i++){
            //     if (debt_records[_exporter][i].amount == need_commit_records[idx].debt.amount && debt_records[_exporter][i].time == need_commit_records[idx].debt.time){
            //         delete_debt(debt_records[_exporter], i);
            //         break;
            //     }
            // }
            // delete_record(need_commit_records, idx);
            need_commit_records[idx].debt.status = false;
            need_commit_records[idx].status = false;
            status = true;
        }
    }


    function add_debt(address _someone, bool _debt_type, uint256 _amount, uint _time) check_permission public returns(bool status) {
        uint _length = debt_records[_someone].length;
        debt_records[_someone].push(Debt(_amount, _debt_type, false, _someone, _time, true));
        status = debt_records[_someone].length - _length == 1 ? true : false;
    }

    function get_money_from_factor(address _factor, uint _amount) private returns(bool) {
        Factoring factoring = Factoring(_factor);
        return factoring.get_money(_amount);
    }

    function clear_cache() check_permission public{
        uint idx = 0;
        while (idx < need_commit_records.length){
            if (need_commit_records[idx].status) { //正常
                idx++;
                continue;
            }
            clear_debt(need_commit_records[idx].debt.owner, need_commit_records[idx].debt.amount, need_commit_records[idx].debt.time);
            delete_record(need_commit_records, idx);
        }
    }

    function clear_debt(address _owner, uint _amount, uint _time) private {
        for (uint i = 0; i < debt_records[_owner].length; ++i){
            if (debt_records[_owner][i].amount == _amount && debt_records[_owner][i].time == _time){
                delete_debt(debt_records[_owner], i);
                return;
            }
        }
    }

    function delete_debt(Debt[] storage debts, uint idx) private {
        for (uint i = idx; i < debts.length - 1; ++i)
            debts[i] = debts[i + 1];
        delete debts[debts.length - 1];
        debts.length--;
    }

    function delete_record(Record[] storage record, uint idx) private {
        for (uint i = idx; i < record.length - 1; ++i)
            record[i] = record[i + 1];
        delete record[record.length - 1];
        record.length--;
    }
}