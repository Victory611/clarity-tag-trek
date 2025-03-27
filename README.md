# TagTrek
A geolocation-based scavenger hunt app for team-building events and educational experiences built on Stacks blockchain.

## Features
- Create and manage scavenger hunt games
- Add location-based checkpoints with clues
- Track team progress and completion status 
- Award points for completed checkpoints
- Verify location proximity for checkpoint validation

## Setup and Installation
1. Clone the repository
2. Install Clarinet (if not already installed)
3. Run `clarinet check` to verify the contract
- Run `clarinet test` to run the test suite

## Usage Examples
```clarity
;; Create a new game (admin only)
(contract-call? .tag-trek create-game "City Adventure" u5)

;; Add checkpoint to game (admin only)
(contract-call? .tag-trek add-checkpoint u1 "Find the statue" 
  "Near the town square" u40.7128 u74.0060 u100)

;; Start game for team
(contract-call? .tag-trek start-game u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Submit checkpoint completion
(contract-call? .tag-trek complete-checkpoint u1 u1 u40.7127 u74.0061)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
