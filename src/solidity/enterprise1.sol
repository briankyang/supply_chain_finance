pragma solidity ^0.4.11;

contract Enterprise {
    address private owner; //合约持有人

    struct Debt{ //债务
        address owner; //用来记录欠债的前属主或转移的保理地址 20
        uint256 amount; //金额  8
        uint256 time; //应还时间 8
        bool debt_type; // 类型， true表示欠债， false表示应收账款 1
        bool is_transferred; //表示是否已转移 1
        bool status; //1
    }

    struct Financing { //记录所获融资
        uint256 amount; //应收账款额 8
        uint256 cash; //可以获得融资额 8
        bool is_done; //是否已到帐 1
    }

    struct Transfer {
        address factor; //20字节
        address exporter; //20字节
        uint256 amount; //8字节
        uint256 time; //8字节
        bool status; //1字节
    }

    mapping (address=>Debt) private debts; //记录债务，囊括欠债和应收账款
    mapping (address=>Financing[]) private financing_records; //融资记录

    // mapping (address=>address) private contract_address; //机构对应的合约地址
    
    Transfer[] private transfer_records;
    
    modifier check_permission() { //权限检查
        require(msg.sender == owner);
        _;
    }
    
    function  Enterprise() public {
        owner = msg.sender;
    }

    function getTransferRecords() view public returns(byte[] data) {
        data = new byte[](transfer_records.length * 57);
        uint idx = 0;
        uint i = 0;
        uint j = 0;
        for (i = 0; i < transfer_records.length; i++){
            for (j = 0; j < 20; ++j)
                data[idx++] = bytes20(transfer_records[i].factor)[j];
            for (j = 0; j < 20; ++j)
                data[idx++] = bytes20(transfer_records[i].exporter)[j];
            for (j = 0; j < 8; ++j)
                data[idx++] = bytes8(transfer_records[i].amount)[j];
            for (j = 0; j < 8; ++j)
                data[idx++] = bytes8(transfer_records[i].time)[j];
            data[idx++] = transfer_records[i].status ? byte(1) : byte(0);
        }
    }

    function addTransferRequest(address _factor, uint256 _amount, uint256 _time) public {
        transfer_records.push(Transfer(_factor, msg.sender, _amount, _time, true));
    }

    function setTransferStatus(address _factor, address _exporter, uint256 _amount, uint256 _time) 
    check_permission public { //merchant使用
        for (uint i = 0; i < transfer_records.length; i++){
            if (transfer_records[i].factor == _factor && 
            transfer_records[i].exporter == _exporter && transfer_records[i].amount == _amount && transfer_records[i].time == _time)
            transfer_records[i].status = false;
        }
    }

    function setDebtStatus(address _owner, uint256 _amount, uint256 _time, bool _status) 
    check_permission public{ //exporter使用
        // status = false;
        // for (uint i = 0; i < debts[_owner].length; ++i) {
        //     if (debts[_owner][i].amount == _amount && 
        //     debts[_owner][i].time == _time && debts[_owner][i].debt_type == false){
        //         debts[_owner][i].status = _status;
        //         status = true;
        //     }
        // }
        debts[_owner].status = false;
    }

    // function commitTransferDebt(address _factor, address _exporter, uint256 _amount, uint256 _time) 
    // check_permission public{//merchant使用，确认转账
    //     // Debt[] storage debts = debts[_exporter];
    //     // for (uint i = 0; i < debts.length; i++){
    //     //     if (debts[i].amount == _amount && debts[i].time == _time){
    //     //         debts[i].status = false;
    //     //         debts[_factor].push(Debt(_exporter, debts[i].amount, debts[i].time, false, true, true));
    //     //         // delete_debt(debts, i);
    //     //         // status = true;
    //     //         break;
    //     //     }
    //     // }
    //     Debt storage debt = debts[_exporter];
    //     if (debt.amount == _amount && debt.time == _time){
    //         debt.status = false;
    //         debts[_factor] = Debt(_exporter, _amount, _time, false, true, true);
    //         }
    // }

    function commitTransferDebt(address _factor, address _exporter, uint256 _amount, uint256 _time) 
    check_permission public{//merchant使用，确认转账
        Debt storage debt = debts[_exporter];
        debt.status = false;
        debts[_factor] = Debt(_exporter, _amount, _time, false, true, true);
    }

    function addFinancing(address _factor, uint256 _amount, uint256 cash, bool is_done) check_permission public {//添加融资记录
        financing_records[_factor].push(Financing(_amount, cash, is_done));
    }

    //TODO 返回记录详情
    function getDebts(address someone) view check_permission public returns(byte[] data){
        Debt storage debt = debts[someone];
        data = new byte[](39);
        uint idx = 0;
        uint j;
        for (j = 0; j < 20; ++j)
            data[idx++] = bytes20(debt.owner)[j];
        for (j = 0; j < 8; ++j)
            data[idx++] = bytes8(debt.amount)[j];
        for (j = 0; j < 8; ++j)
            data[idx++] = bytes8(debt.time)[j];
        data[idx++] = debt.debt_type ? byte(1) : byte(0);
        data[idx++] = debt.is_transferred ? byte(1) : byte(0);
        data[idx++] = debt.status ? byte(1) : byte(0);
    }

    function getFinancing(address someone) view check_permission public returns(byte[] data) {
        Financing[] storage financing = financing_records[someone];
        data = new byte[](financing.length * 17);
        uint idx = 0;
        uint j;
        for (uint i = 0; i < financing.length; ++i){
            for (j = 0; j < 8; ++j)
                data[idx++] = bytes8(financing[i].amount)[j];
            for (j = 0; j < 8; ++j)
                data[idx++] = bytes8(financing[i].cash)[j];
            data[idx++] = financing[i].is_done ? byte(1) : byte(0);
        }
    }

    function addDebt(address _someone, bool _debt_type, uint256 _amount, uint256 _time) 
    check_permission public returns(bool status) {
        debts[_someone] = Debt(_someone, _amount, _time, _debt_type, false, true);
    }
}