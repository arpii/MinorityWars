var MinorityWars = artifacts.require("MinorityWars");

contract('MinorityWars', (accounts) => {
  let contract;
  const ownerAccount = accounts[0];

  const landCount = 10;
  const buyDictatorDividendRatio = 40;
  const moveFee = Number(web3.toWei("20", "finney"));
  const moveLandDividend = Number(web3.toWei("12", "finney"));
  const dictatorPriceIncrement = Number(web3.toWei("10", "finney"));

  const address0 = "0x0000000000000000000000000000000000000000";

  beforeEach(async () => {
    // Constructor
    contract = await MinorityWars.new({from: ownerAccount});
  });

  afterEach(async () => {
  });

  async function check(dataType, args, expect) {
    let data;
    if (dataType === 'playerMap') {
      data = await contract.playerMap.call(args);
    }
    else if(dataType === 'landMap') {
      data = await contract.landMap.call(args);
    }

    await data.forEach(async function(part, index, theArray) {
      if (typeof(part) === 'object') {  // BigNumber
        theArray[index] = await part.toNumber();
      }
      else {
        theArray[index] = part;
      }
    });
    if (dataType === 'landMap') {
      assert.deepEqual(data.slice(0, data.length - 1), expect);
    }
    else {
      assert.deepEqual(data, expect);
    }
  }

  /* test move */

  it("Test basic move", async () => {
    let land;

    // p3 move to land 4
    land = 4;
    await contract.move(land, {from: accounts[3], value: moveFee});
    await check('playerMap', accounts[3], [moveFee, 0, 0, 1, land, false, false]);
    await check('landMap', land, [moveFee, 0, address0, 1, ""]);
  });

  it("Test move but doesn't get experience", async () => {
    let player;
    await contract.move(1, {from: accounts[1], value: moveFee});
    await contract.move(2, {from: accounts[2], value: moveFee});
    // p3 should not get exp
    await contract.move(1, {from: accounts[3], value: moveFee});
    await check('playerMap', accounts[3], [moveFee, 0, 0, 0, 1, false, false]);
  });

  it("Test invalid land in move", async () => {
    try {
      await contract.move(0, {from: accounts[2], value: moveFee});
    } catch(e) {
      return;
    }
    assert(false);
  });

  it("Test invalid land in move 2", async () => {
    try {
      await contract.move(landCount + 100, {from: accounts[2], value: moveFee});
    } catch(e) {
      return;
    }
    assert(false);
  });

  /* test buy */

  it("Test basic buy", async () => {
    let land;

    // p1 move to land 1
    land = 1;
    await contract.move(land, {from: accounts[1], value: moveFee});
    await check('playerMap', accounts[1], [moveFee, 0, 0, 1, land, false, false]);
    await check('landMap', land, [moveFee, 0, address0, 1, ""]);

    // p1 move to land 3
    land = 3;
    await contract.move(land, {from: accounts[1], value: moveFee});
    await check('playerMap', accounts[1], [moveFee * 2, 0, 0, 2, land, false, false]);
    await check('landMap', land, [moveFee * 2, 0, address0, 1, ""]);

    // p1 move to land 5
    land = 5;
    await contract.move(land, {from: accounts[1], value: moveFee});
    await check('playerMap', accounts[1], [moveFee * 3, 0, 0, 3, land, false, false]);
    await check('landMap', land, [moveFee * 3, 0, address0, 1, ""]);

    // p1 buy land max landCount
    land = landCount;
    await contract.buy(land, {from: accounts[1], value: 0});
    await check('playerMap', accounts[1], [moveFee * 3, 0, 0, 0, land, true, false]);
    await check('landMap', land, [moveFee * 3, dictatorPriceIncrement, accounts[1], 1, ""]);

    let totalBonus = await contract.totalBonus.call();
    totalBonus = await totalBonus.toNumber();
    assert.equal(totalBonus, moveFee * 3);
  });

  it("Test dictator dividend", async () => {
    await contract.move(1, {from: accounts[1], value: moveFee});
    await contract.move(2, {from: accounts[1], value: moveFee});
    await contract.move(3, {from: accounts[1], value: moveFee});
    // p1 is dictator of land 1
    await contract.buy(1, {from: accounts[1], value: 0});

    // p2 move to land 1
    await contract.move(1, {from: accounts[2], value: moveFee});
    await check('playerMap', accounts[1], [moveFee * 3, moveLandDividend, moveLandDividend, 0, 1, true, false]);
    // p3 move to land 1
    await contract.move(1, {from: accounts[3], value: moveFee});
    await check('playerMap', accounts[1], [moveFee * 3, moveLandDividend * 2, moveLandDividend * 2, 0, 1, true, false]);
    await check('landMap', 1, [moveFee * 3 + moveFee * 2, dictatorPriceIncrement, accounts[1], 3, ""]);

    let totalBonus = await contract.totalBonus.call();
    totalBonus = await totalBonus.toNumber();
    assert.equal(totalBonus, moveFee * 3 + (moveFee - moveLandDividend) + (moveFee - moveLandDividend));
  });

  it("Test dictator buy", async () => {
    await contract.move(1, {from: accounts[1], value: moveFee});
    await contract.move(2, {from: accounts[1], value: moveFee});
    await contract.move(3, {from: accounts[1], value: moveFee});
    // p1 is dictator of land 1
    await contract.buy(1, {from: accounts[1], value: 0});

    // p2 move to land 1
    await contract.move(4, {from: accounts[2], value: moveFee});
    await contract.move(5, {from: accounts[2], value: moveFee});
    await contract.move(6, {from: accounts[2], value: moveFee});
    // p2 buy land 1 without enough money
    success = false;
    try {
      await contract.buy(1, {from: accounts[2], value: 0});
    } catch(e) {
      success = true;
    }
    assert(success);

    //p2 buy land 1
    await contract.buy(1, {from: accounts[2], value: dictatorPriceIncrement});
    let dictatorDividend = dictatorPriceIncrement * buyDictatorDividendRatio / 100;
    await check('playerMap', accounts[1], [moveFee * 3, dictatorDividend, dictatorDividend, 0, 1, false, false]);
    await check('playerMap', accounts[2], [moveFee * 3 + dictatorPriceIncrement, 0, 0, 0, 1, true, false]);
    await check('landMap', 1, [(moveFee * 3) + (moveFee * 3 + dictatorPriceIncrement), dictatorPriceIncrement * 2, accounts[2], 2, ""]);
    await check('landMap', 6, [0, 0, address0, 0, ""]);

    let totalBonus = await contract.totalBonus.call();
    totalBonus = await totalBonus.toNumber();
    assert.equal(totalBonus, moveFee * 6 + (dictatorPriceIncrement - dictatorDividend) );
  });

  it("Test invalid buy", async () => {
    try {
      await contract.buy(2, {from: accounts[2], value: moveFee});
    } catch(e) {
      return;
    }
    assert(false);
  });

  it("Test not enough exp to buy", async () => {
    try {
      await contract.buy(1, {from: accounts[2], value: dictatorPriceIncrement * 100});
    } catch(e) {
      return;
    }
    assert(false);
  });
});
