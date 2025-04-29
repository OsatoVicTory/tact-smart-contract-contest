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

contract Proposal {

    voters: map<Address, Bool>;
    yesCount: Int as uint32 = 0;
    noCount: Int as uint32 = 0;
    proposalId: Int as uint32 = 0;
    votingEndingAt: Int as uint32;

    init(data: Init) {
        self.proposalId = data.proposalId;
        self.votingEndingAt = data.votingEndingAt;
    }

    // deploy
    receive() { }

    receive(msg: Vote) {
        throwIf(400, now() > self.votingEndingAt); // deadline reached
        throwIf(401, self.noCount + self.yesCount == 100); // more than 100
        let sender: Address = sender();
        throwIf(403, self.voters.exists(sender)); // already voted
        self.voters.set(sender, true);
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