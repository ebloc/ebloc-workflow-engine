// SPDX-License-Identifier: MIT

/*
  file:   Lib.sol
  author: Alper Alimoglu
  email:  alper.alimoglu AT gmail.com
*/

pragma solidity >=0.7.0 <0.9.0;

library Lib {
    enum CacheType {
        PUBLIC, /* 0 */
        PRIVATE /* 1 */
    }

    enum CloudStorageID {
        IPFS, /* 0 */
        IPFS_GPG, /* 1 */
        NONE, /* 2 Request to use from registered/cached data */
        EUDAT, /* 3 */
        GDRIVE /* 4 */
    }

    /* Status of the submitted job Enum */
    enum JobStateCodes {
        /* Following states {0, 1, 2} will allow to request refund */
        SUBMITTED, /* 0 Initial state */
        PENDING,
        /* 1 Indicates when a request is receieved by the provider. The
         * job is waiting for resource allocation. It will eventually
         * run. */
        RUNNING,
        /* 2 The job currently is allocated to a node and is
         * running. Corresponding data files are downloaded and
         * verified.*/
        /* Following states {3, 4, 5} used to prevent double spending */
        REFUNDED, /* 3 Indicates if job is refunded */
        CANCELLED,
        /* 4 Job was explicitly cancelled by the requester or system
         * administrator. The job may or may not have been
         * initiated. Set by the requester*/
        COMPLETED,
        /* 5 The job has completed successfully and deposit is paid
         * to the provider */
        TIMEOUT, /* 6 Job terminated upon reaching its time limit. */
        COMPLETED_WAITING_ADDITIONAL_DATA_TRANSFER_OUT_DEPOSIT /* 7  */
    }

    struct JobArgument {
        /* An Ethereum address value containing the Ethereum address of the
         * provider that is requested to run the job. */
        address payable provider;
        /* A uint32 value containing the block number when the requested
         * provider set its prices most recent. */
        uint32 priceBlockIndex;
        /* An array of uint8 values that denote whether the requester’s data is
           stored and shared using either IPFS, EUDAT, IPFS (with GPG
           encryption), or Google Drive. */
        uint8[] cloudStorageID;
        /* An array of uint8 values that denote whether the requester’s data
            will be cached privately within job owner's home directory, or
            publicly for other requesters' access within a shared directory for
            all the requesters.
         */
        uint8[] cacheType;
        /* An array of uint32 values that denote whether the provider’s
         * registered data will be used or not. */
        uint32[] dataPricesSetBlockNum;
        uint16[] core;
        uint16[] runTime;
        uint32 dataTransferOut;
    }

    struct JobIndexes {
        uint32 index;
        uint32 jobID;
        uint32 endTimestamp;
        uint32 dataTransferIn;
        uint32 dataTransferOut;
        uint32 elapsedTime;
        uint256[] core;
        uint256[] runTime;
        bool endJob;
    }

    struct DataInfo {
        uint32 price;
        uint32 commitmentBlockDur;
    }

    struct Storage {
        uint256 received; // received payment for storage usage
    }

    struct JobStorage {
        uint32 receivedBlock;
        uint32 storageDuration;
        bool isPrivate;
        bool isVerifiedUsed; // Set to `true` if the provided used and verified the given code hash
        //address      owner; //Cloud be multiple owners
    }

    struct RegisteredData {
        uint32[] committedBlock; // Block number when data is registered
        mapping(uint256 => DataInfo) dataInfo;
    }

    struct Job {
        JobStateCodes stateCode; // Assigned by the provider
        uint32 startTimestamp; // Submitted job's starting universal time on the server side. Assigned by the provider
    }

    // Submitted Job's information
    struct Status {
        uint32 cacheCost;
        uint32 dataTransferIn;
        uint32 dataTransferOut;
        uint32 pricesSetBlockNum; // When provider is submitted provider's most recent block number when its set or updated
        uint256 received; // Paid amount (new owned) by the client
        address payable jobOwner; // Address of the client (msg.sender) has been stored
        bytes32 sourceCodeHash; // keccak256 of the list of sourceCodeHash list concatinated with the cacheType list
        bytes32 jobInfo;
        mapping(uint256 => Job) jobs;
    }

    struct ProviderInfo {
        uint32 availableCore; // Registered core number of the provider
        uint32 commitmentBlockDur;
        /* All the price varaibles are defined in Gwei.
           Floating-point or fixed-point decimals have not yet been implemented in Solidity */
        uint32 priceCoreMin; // Provider's price for core per minute
        uint32 priceDataTransfer;
        uint32 priceStorage;
        uint32 priceCache;
    }

    struct Provider {
        uint32 committedBlock; // Block number when  is registered in order the watch provider's event activity
        bool isRunning; // Flag that checks is Provider running or not
        mapping(uint256 => ProviderInfo) info;
        mapping(bytes32 => JobStorage) jobSt; // Stored information related to job's storage time
        mapping(bytes32 => RegisteredData) registeredData;
        mapping(address => mapping(bytes32 => Storage)) storageInfo;
        mapping(string => Status[]) jobStatus; // All submitted jobs into provider 's Status is accessible
    }

    /**
     *@dev Invoked when registerProvider() function is called
     *@param self | Provider struct
     */
    function construct(Provider storage self) internal {
        self.isRunning = true;
        self.committedBlock = uint32(block.number);
    }

}
