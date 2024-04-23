pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;
contract Medishield {
    struct Patient {
        string name;
        uint number;
        address[] healthcareAccessList;
        uint[] diagnosis;
        string record;
        string[] recordHashes; // Array to store IPFS hashes
    }

    struct Healthcare {
        string name;
        uint number;
        uint designation;
        address[] patientAccessList;
    }

    uint creditPool;

    address[] public patientList;
    address[] public healthcareList;

    mapping(address => Patient) patientInfo;
    mapping(address => Healthcare) healthcareInfo;
    mapping(address => address) Empty;

    // Function to add agent (patient or healthcare provider)
    function add_agent(
        string memory _name,
        uint _number,
        uint _designation,
        string memory _hash
    ) public returns (string memory) {
        address addr = msg.sender;

        if (_designation == 0) {
            Patient memory p;
            p.name = _name;
            p.number = _number;
            p.record = _hash;

            patientInfo[msg.sender] = p;
            patientList.push(addr) - 1;
            return _name;
        } else if (_designation == 1 || _designation == 2) {
            Healthcare memory d;
            d.name = _name;
            d.number = _number;
            d.designation = _designation;
            healthcareInfo[msg.sender] = d;
            healthcareList.push(addr) - 1;
            return _name;
        } else {
            revert();
        }
    }
    function get_patient(
        address addr
    )
        public
        view
        returns (string memory, uint, uint[] memory, address, string memory)
    {
        // if(keccak256(patientInfo[addr].name) == keccak256(""))revert();
        return (
            patientInfo[addr].name,
            patientInfo[addr].number,
            patientInfo[addr].diagnosis,
            Empty[addr],
            patientInfo[addr].record
        );
    }
    // Function to upload patient record by patient
    function uploadPatientRecord(string memory _recordHash) public {
        patientInfo[msg.sender].recordHashes.push(_recordHash);
    }

    // Function to get number of patient record hashes
    function getPatientRecordCount(address addr) public view returns (uint) {
        return patientInfo[addr].recordHashes.length;
    }

    // Function to get individual patient record hash by index
    function getPatientRecord(
        uint index,
        address addr
    ) public view returns (string memory) {
        require(index < patientInfo[addr].recordHashes.length, "Invalid index");
        return patientInfo[addr].recordHashes[index];
    }

    // Function to get all patient record hashes
    function getAllPatientRecords(
        address addr
    ) public view returns (uint, string[] memory) {
        uint recordCount = getPatientRecordCount(addr);
        string[] memory allRecords = new string[](recordCount);

        for (uint i = 0; i < recordCount; i++) {
            allRecords[i] = getPatientRecord(i, addr);
        }

        return (recordCount, allRecords);
    }

    function get_healthcare(
        address addr
    ) public view returns (string memory, uint, uint256) {
        // if(keccak256(healthcareInfo[addr].name)==keccak256(""))revert();
        return (
            healthcareInfo[addr].name,
            healthcareInfo[addr].number,
            healthcareInfo[addr].designation
        );
    }
    function get_patient_healthcare_name(
        address paddr,
        address daddr
    ) public view returns (string memory, string memory) {
        return (patientInfo[paddr].name, healthcareInfo[daddr].name);
    }

    function permit_access(address addr) public payable {
        require(msg.value == 2 ether);

        creditPool += 2;

        healthcareInfo[addr].patientAccessList.push(msg.sender) - 1;
        patientInfo[msg.sender].healthcareAccessList.push(addr) - 1;
    }

    //must be called by healthcare.
    function submitfile(
        address paddr,
        uint _diagnosis,
        string memory _hash
    ) public {
        bool patientFound = false;
        for (
            uint i = 0;
            i < healthcareInfo[msg.sender].patientAccessList.length;
            i++
        ) {
            if (healthcareInfo[msg.sender].patientAccessList[i] == paddr) {
                msg.sender.transfer(2 ether);
                creditPool -= 2;
                patientFound = true;
            }
        }
        if (patientFound == true) {
            set_hash(paddr, _hash);
            remove_patient(paddr, msg.sender);
        } else {
            revert();
        }

        bool DiagnosisFound = false;
        for (uint j = 0; j < patientInfo[paddr].diagnosis.length; j++) {
            if (patientInfo[paddr].diagnosis[j] == _diagnosis)
                DiagnosisFound = true;
        }
    }

    function remove_element_in_array(
        address[] storage Array,
        address addr
    ) internal returns (uint) {
        bool check = false;
        uint del_index = 0;
        for (uint i = 0; i < Array.length; i++) {
            if (Array[i] == addr) {
                check = true;
                del_index = i;
            }
        }
        if (!check) revert();
        else {
            if (Array.length == 1) {
                delete Array[del_index];
            } else {
                Array[del_index] = Array[Array.length - 1];
                delete Array[Array.length - 1];
            }
            Array.length--;
        }
    }

    function remove_patient(address paddr, address daddr) public {
        remove_element_in_array(healthcareInfo[daddr].patientAccessList, paddr);
        remove_element_in_array(patientInfo[paddr].healthcareAccessList, daddr);
    }

    function get_accessed_healthcarelist_for_patient(
        address addr
    ) public view returns (address[] memory) {
        address[] storage healthcareaddr = patientInfo[addr]
            .healthcareAccessList;
        return healthcareaddr;
    }
    function get_accessed_patientlist_for_healthcare(
        address addr
    ) public view returns (address[] memory) {
        return healthcareInfo[addr].patientAccessList;
    }

    function revoke_access(address daddr) public payable {
        remove_patient(msg.sender, daddr);
        msg.sender.transfer(2 ether);
        creditPool -= 2;
    }

    function get_patient_list() public view returns (address[] memory) {
        return patientList;
    }

    function get_healthcare_list() public view returns (address[] memory) {
        return healthcareList;
    }

    function get_hash(address paddr) public view returns (string memory) {
        return patientInfo[paddr].record;
    }

    function set_hash(address paddr, string memory _hash) internal {
        patientInfo[paddr].record = _hash;
    }
}
