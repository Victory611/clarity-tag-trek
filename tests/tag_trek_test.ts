import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test game creation - admin only",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Test creating game as admin
    let block = chain.mineBlock([
      Tx.contractCall('tag-trek', 'create-game', 
        [types.ascii("City Adventure"), types.uint(5)], 
        deployer.address)
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Test creating game as non-admin (should fail)
    block = chain.mineBlock([
      Tx.contractCall('tag-trek', 'create-game',
        [types.ascii("Failed Game"), types.uint(3)],  
        wallet1.address)
    ]);
    block.receipts[0].result.expectErr().expectUint(100);
  }
});

Clarinet.test({
  name: "Test checkpoint management",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // Create game first
    chain.mineBlock([
      Tx.contractCall('tag-trek', 'create-game',
        [types.ascii("City Adventure"), types.uint(5)],
        deployer.address)
    ]);
    
    // Add checkpoint
    let block = chain.mineBlock([
      Tx.contractCall('tag-trek', 'add-checkpoint',
        [types.uint(1),
         types.ascii("Find the statue"),
         types.ascii("Near town square"),
         types.uint(407128),
         types.uint(740060),
         types.uint(100)],
        deployer.address)
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Verify checkpoint exists
    let response = chain.callReadOnlyFn('tag-trek', 'get-checkpoint',
      [types.uint(1), types.uint(1)],
      deployer.address
    );
    response.result.expectSome();
  }
});

Clarinet.test({
  name: "Test game play functionality",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const player = accounts.get('wallet_1')!;
    
    // Setup game and checkpoint
    chain.mineBlock([
      Tx.contractCall('tag-trek', 'create-game',
        [types.ascii("City Adventure"), types.uint(5)],
        deployer.address),
      Tx.contractCall('tag-trek', 'add-checkpoint',
        [types.uint(1),
         types.ascii("Find the statue"),
         types.ascii("Near town square"),
         types.uint(407128),
         types.uint(740060),
         types.uint(100)],
        deployer.address)
    ]);
    
    // Start game for team
    let block = chain.mineBlock([
      Tx.contractCall('tag-trek', 'start-game',
        [types.uint(1), types.principal(player.address)],
        player.address)
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Complete checkpoint
    block = chain.mineBlock([
      Tx.contractCall('tag-trek', 'complete-checkpoint',
        [types.uint(1),
         types.uint(1),
         types.uint(407128),
         types.uint(740060)],
        player.address)
    ]);
    block.receipts[0].result.expectOk();
  }
});
