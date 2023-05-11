// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IERC20Token {
    function transfer(address, uint256) external returns (bool);

    function approve(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract InsurancePlatform {
    using SafeMath for uint256;

    uint internal policyCount = 0;
    address internal celoTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    struct Policy {
        address payable insured;
        address payable insurer;
        uint256 premium;
        uint256 coverage;
        uint256 expirationDate;
        bool isActive;
        bool isClaimed;
    }

    mapping(uint => Policy) internal policies;

    event PolicyCreated(
        uint indexed policyId,
        address indexed insured,
        address indexed insurer,
        uint256 premium,
        uint256 coverage,
        uint256 expirationDate
    );

    event PolicyClaimed(uint indexed policyId, address indexed insured, uint256 claimAmount);

    function createPolicy(
        address payable _insurer,
        uint256 _premium,
        uint256 _coverage,
        uint256 _expirationDate
    ) external {
        require(_insurer != address(0), "Invalid insurer address");
        require(_premium > 0, "Premium must be greater than zero");
        require(_coverage > 0, "Coverage amount must be greater than zero");
        require(_expirationDate > block.timestamp, "Expiration date must be in the future");

        Policy storage newPolicy = policies[policyCount];
        newPolicy.insured = payable(msg.sender);
        newPolicy.insurer = _insurer;
        newPolicy.premium = _premium;
        newPolicy.coverage = _coverage;
        newPolicy.expirationDate = _expirationDate;
        newPolicy.isActive = true;
        newPolicy.isClaimed = false;

        emit PolicyCreated(
            policyCount,
            newPolicy.insured,
            newPolicy.insurer,
            newPolicy.premium,
            newPolicy.coverage,
            newPolicy.expirationDate
        );

        policyCount++;
    }

    function claimPolicy(uint _policyId) external {
        require(_policyId < policyCount, "Invalid policy ID");

        Policy storage policy = policies[_policyId];
        require(msg.sender == policy.insured, "Only the insured can claim the policy");
        require(policy.isActive, "Policy is not active");
        require(!policy.isClaimed, "Policy has already been claimed");
        require(block.timestamp > policy.expirationDate, "Policy has not expired yet");

        uint256 claimAmount = policy.coverage;
        policy.isClaimed = true;

        require(
            IERC20Token(celoTokenAddress).transfer(policy.insured, claimAmount),
            "Failed to transfer claim amount"
        );

        emit PolicyClaimed(_policyId, policy.insured, claimAmount);
    }

    function getPolicy(uint _policyId) public view returns (
        address payable insured,
        address
                payable insurer,
        uint256 premium,
        uint256 coverage,
        uint256 expirationDate,
        bool isActive,
        bool isClaimed
    ) {
        require(_policyId < policyCount, "Invalid policy ID");

        Policy storage policy = policies[_policyId];

        return (
            policy.insured,
            policy.insurer,
            policy.premium,
            policy.coverage,
            policy.expirationDate,
            policy.isActive,
            policy.isClaimed
        );
    }

    function getPolicyCount() public view returns (uint) {
        return policyCount;
    }
}

