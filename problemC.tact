// 
// Public solution template
//

message Vote {
    value: Bool;
}

struct ProposalState {
    yesCount: Int as uint32;
    noCount: Int as uint32;
}

struct Init {
    proposalId: Int as uint32;
    votingEndingAt: Int as uint32;
}

asm fun asmGetHash(c: Cell): Int {
    HASHCU
}

contract Proposal {

    // proposalId: Int as uint32;
    votingEndingAt: Int as uint32;
    voters: map<Int as uint8, Bool>;
    yesCount: Int as uint32 = 0;
    noCount: Int as uint32 = 0;

    init(data: Init) {
        // self.proposalId = data.proposalId;
        self.votingEndingAt = data.votingEndingAt;
    }

    // deploy
    receive() { }

    receive(msg: Vote) {
        throwIf(400, now() > self.votingEndingAt);
        let sender: Address = sender();
        let s: Cell = beginCell().storeAddress(sender).endCell();
        let sHash: Int = asmGetHash(s);
        let hash: Int = sHash % 150;
        throwIf(401, self.voters.exists(hash));
        self.voters.set(hash, true);
        if(msg.value) {
            self.yesCount += 1;
        } else {
            self.noCount += 1;
        }
        cashback(sender);
    }

    get fun proposalState(): ProposalState {
        return ProposalState{yesCount: self.yesCount, noCount: self.noCount};
    }

}