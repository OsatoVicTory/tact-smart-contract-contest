struct ProposalInit {
    master: Address;
    proposalId: Int as uint32;
}

message DeployNewProposal {
    votingEndingAt: Int as uint32;
}

message DeployedProposal {
    votingEndingAt: Int as uint32;
    sender: Address;
}


contract ProposalMaster {

    proposalId: Int as uint32 = 0;

    receive() { 
        let c: Int = context().value;
        let tn: Int = ton("0.01");
        if(c > tn) {
            message(MessageParameters{
                to: sender(),
                value: c - tn,
                mode: SendIgnoreErrors,
                body: null,
            });
        }
    }

    receive(msg: DeployNewProposal) {
        throwIf(400, now() > msg.votingEndingAt);
        deploy(DeployParameters{
            init: initOf Proposal(ProposalInit{master: myAddress(), proposalId: self.proposalId}),
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
            body: DeployedProposal{votingEndingAt: msg.votingEndingAt, sender: sender()}.toCell(),
        });
        self.proposalId += 1;
    }

    get fun nextProposalId(): Int {
        return self.proposalId;
    }
}

// ==============================================================================

message Vote {
    value: Bool;
}

struct ProposalState {
    yesCount: Int as uint32;
    noCount: Int as uint32;
    master: Address;
    proposalId: Int as uint32;
    votingEndingAt: Int as uint32;
}

contract Proposal {

    master: Address;
    proposalId: Int as uint32;
    votingEndingAt: Int as uint32 = 0;
    yesCount: Int as uint32 = 0;
    noCount: Int as uint32 = 0;
    voters: map<Address, Bool>;

    init(data: ProposalInit) {
        let p: StateInit = initOf ProposalMaster();
        throwUnless(2025, p.hasSameBasechainAddress(sender()));
        self.master = data.master;
        self.proposalId = data.proposalId;
    }

    // deploy
    receive() { }

    receive(msg: DeployedProposal) {
        throwUnless(2025, sender() == self.master);
        self.votingEndingAt = msg.votingEndingAt;
        cashback(msg.sender);
    }

    receive(msg: Vote) {
        throwIf(400, now() > self.votingEndingAt);
        throwIf(401, self.yesCount + self.noCount == 100);
        let sender: Address = sender();
        throwIf(403, self.voters.exists(sender));
        self.voters.set(sender, true);
        if(msg.value) {
            self.yesCount += 1;
        } else {
            self.noCount += 1;
        }
        cashback(sender());
    }

    get fun proposalState(): ProposalState {
        return ProposalState{yesCount: self.yesCount, noCount: self.noCount, master: self.master, proposalId: self.proposalId, votingEndingAt: self.votingEndingAt};
    }
}