//==============================================================================
/* aiEconomy.xs

	This file is intended for economy related stuffs, such as gatherer
	management and resource building construction.

*/
//==============================================================================

//==============================================================================
//==============================================================================
// Economy
//==============================================================================
//==============================================================================

//==============================================================================
// updateResourceDistribution
/*
	Predict our resource needs based on plan costs and resource crates we are going
	to ship.
*/
//==============================================================================
void updateResourceDistribution()
{
	float planFoodNeeded = 0.0;
	float planWoodNeeded = 0.0;
	float planGoldNeeded = 0.0;
	float totalPlanFoodNeeded = 0.0;
	float totalPlanWoodNeeded = 0.0;
	float totalPlanGoldNeeded = 0.0;
	float foodAmount = 0.0;
	float woodAmount = 0.0;
	float goldAmount = 0.0;
	float foodNeeded = 0.0;
	float woodNeeded = 0.0;
	float goldNeeded = 0.0;
	float totalNeeded = 0.0;
	int planID = -1;
	int trainUnitType = -1;
	int trainCount = 0;
	int numPlans = aiPlanGetActiveCount();
	int planType = -1;
	float foodGatherRate = 0.0;
	float woodGatherRate = 0.0;
	float goldGatherRate = 0.0;
	float goldPercentage = 0.0;
	float woodPercentage = 0.0;
	float foodPercentage = 0.0;
	float lastGoldPercentage = aiGetResourcePercentage(cResourceGold);
	float lastWoodPercentage = aiGetResourcePercentage(cResourceWood);
	float lastFoodPercentage = aiGetResourcePercentage(cResourceFood);
	int planPri = 50;
	int highestPri = 50;
	int highestPriPlanID = -1;
	float highestPriPlanGoldNeeded = 0.0;
	float highestPriPlanWoodNeeded = 0.0;
	float highestPriPlanFoodNeeded = 0.0;
	int ageUpPolitician = -1;
	int numberSendingCards = aiHCGetNumberSendingCards();
	int cardIndex = -1;
	int cardFlags = 0;
	int crateQuery = createSimpleUnitQuery(cUnitTypeAbstractResourceCrate, cMyID, cUnitStateAlive);
	int numberCrates = kbUnitQueryExecute(crateQuery);
	int crateID = -1;
	float handicap = kbGetPlayerHandicap(cMyID);
	float cost = 0.0;
	float trainPoints = 0.0;
	int numberBuildingsWanted = 0;
	float villagerCost = 0;
	int villagerTrainTime = 0;

	aiSetResourceGathererPercentageWeight(cRGPScript, 1.0);
	aiSetResourceGathererPercentageWeight(cRGPCost, 0.0);

	debugEconomy("updateResourceDistribution(): number plans="+numPlans);
	for (i = 0; < numPlans)
	{
		planID = aiPlanGetIDByActiveIndex(i);
		planType = aiPlanGetType(planID);
		planPri = aiPlanGetDesiredResourcePriority(planID);
		if (planType == cPlanTrain ||
			planType == cPlanBuild ||
			planType == cPlanBuildWall ||
			planType == cPlanResearch ||
			planType == cPlanRepair)
		{
			if (planID == aiPlanGetIDByTypeAndVariableType(cPlanTrain, cTrainPlanUnitType, gEconUnit))
				continue;
			else
			{
				planFoodNeeded = aiPlanGetFutureNeedsCostPerResource(planID, cResourceFood);
				planWoodNeeded = aiPlanGetFutureNeedsCostPerResource(planID, cResourceWood);
				planGoldNeeded = aiPlanGetFutureNeedsCostPerResource(planID, cResourceGold);
			}
			totalPlanFoodNeeded = totalPlanFoodNeeded + planFoodNeeded;
			totalPlanWoodNeeded = totalPlanWoodNeeded + planWoodNeeded;
			totalPlanGoldNeeded = totalPlanGoldNeeded + planGoldNeeded;
			if (planPri > highestPri)
			{
				highestPri = planPri;
				highestPriPlanID = planID;
				highestPriPlanFoodNeeded = planFoodNeeded;
				highestPriPlanWoodNeeded = planWoodNeeded;
				highestPriPlanGoldNeeded = planGoldNeeded;
			}
			debugEconomy("updateResourceDistribution(): name="+aiPlanGetName(planID)+", needed=("+planGoldNeeded+", "+planWoodNeeded+", "+planFoodNeeded+")");
		}
	}

	foodAmount = kbResourceGet(cResourceFood);
	woodAmount = kbResourceGet(cResourceWood);
	goldAmount = kbResourceGet(cResourceGold);

	if (kbGetAge() < cAge4)
	{
		// ----- Food Gather Rate -----
		if (cMyCiv == cCivJapanese)
			foodGatherRate = kbProtoUnitGetGatherRate(gEconUnit, cUnitTypeypBerryBuilding) * handicap;
		else
			foodGatherRate = kbProtoUnitGetGatherRate(gEconUnit, cUnitTypeHuntable) * handicap;
		// ----- Wood Gather Rate -----
		woodGatherRate = kbProtoUnitGetGatherRate(gEconUnit, cUnitTypeTree) * handicap;
		// ----- Gold Gather Rate -----
		if (cMyCiv == cCivXPIroquois || cMyCiv == cCivXPSioux)
			goldGatherRate = kbProtoUnitGetGatherRate(gEconUnit, cUnitTypedeFurTrade) * handicap;
		else
			goldGatherRate = kbProtoUnitGetGatherRate(gEconUnit, cUnitTypeAbstractMine) * handicap;
	}
	else
	{
		// ----- Food Gather Rate -----
		if (civIsAsian() || civIsAfrican())
			foodGatherRate = kbProtoUnitGetGatherRate(gEconUnit, gFarmUnit, cResourceFood) * handicap;
		else
			foodGatherRate = kbProtoUnitGetGatherRate(gEconUnit, gFarmUnit) * handicap;
		// ----- Wood Gather Rate -----
		woodGatherRate = kbProtoUnitGetGatherRate(gEconUnit, cUnitTypeTree) * handicap;
		// ----- Gold Gather Rate -----
		if (civIsAsian() || civIsAfrican())
			goldGatherRate = kbProtoUnitGetGatherRate(gEconUnit, gPlantationUnit, cResourceGold) * handicap;
		else
			goldGatherRate = kbProtoUnitGetGatherRate(gEconUnit, gPlantationUnit) * handicap;
	}

	// Failsafe.
	if (foodGatherRate < 0.1)
		foodGatherRate = 0.84 * handicap;
	if (woodGatherRate < 0.1)
		woodGatherRate = 0.5 * handicap;
	if (goldGatherRate < 0.1)
		goldGatherRate = 0.6 * handicap;

	// Set reserved villagers for more villager training.
	gReservedFoodVillagers = 0;
	gReservedWoodVillagers = 0;
	gReservedGoldVillagers = 0;
	if (cMyCiv != cCivOttomans)
	{
		villagerCost = kbUnitCostPerResource(gEconUnit, cResourceFood);
		villagerTrainTime = kbUnitGetTrainPoints(gEconUnit);
		switch (cMyCiv)
		{
			case cCivDutch:
			{
				villagerCost = kbUnitCostPerResource(gEconUnit, cResourceGold);
				if (goldAmount < villagerCost * 1.25)
					gReservedGoldVillagers = getCeiling((villagerCost) / (goldGatherRate * villagerTrainTime));
				if (gReservedGoldVillagers < 2)
					gReservedGoldVillagers = 2;
				break;
			}
			case cCivIndians:
			{
				villagerCost = kbUnitCostPerResource(gEconUnit, cResourceWood);
				if (woodAmount < villagerCost * 1.25)
					gReservedWoodVillagers = getCeiling((villagerCost) / (woodGatherRate * villagerTrainTime));
				if (gReservedWoodVillagers < 2)
					gReservedWoodVillagers = 2;
				break;
			}
			default:
			{
				if (foodAmount < villagerCost * 1.25)
					gReservedFoodVillagers = getCeiling((villagerCost) / (foodGatherRate * villagerTrainTime));
				if (gReservedFoodVillagers < 2)
					gReservedFoodVillagers = 2;
				break;
			}
		}
	}

	// Add incoming resources from aging up.
	if (agingUp() == true)
	{
		if (aiPlanGetType(gAgeUpResearchPlan) == cPlanBuild)
		{
			ageUpPolitician = aiPlanGetVariableInt(gAgeUpResearchPlan, cBuildPlanBuildingTypeID, 0);
			ageUpPolitician = kbProtoUnitGetAssociatedTech(ageUpPolitician);
		}
		else
		{
			ageUpPolitician = aiPlanGetVariableInt(gAgeUpResearchPlan, cResearchPlanTechID, 0);
		}
		
		foodAmount = foodAmount + kbTechGetHCCardValuePerResource(ageUpPolitician, cResourceFood) * handicap;
		woodAmount = woodAmount + kbTechGetHCCardValuePerResource(ageUpPolitician, cResourceWood) * handicap;
		goldAmount = goldAmount + kbTechGetHCCardValuePerResource(ageUpPolitician, cResourceGold) * handicap;
	}

	// Add incoming resources from HC shipments.
	for (i = 0; < numberSendingCards)
	{
		cardIndex = aiHCGetSendingCardIndex(i);
		cardFlags = aiHCDeckGetCardFlags(gDefaultDeck, cardIndex);
		if ((cardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate)
		{
			foodAmount = foodAmount + aiHCDeckGetCardValuePerResource(gDefaultDeck, cardIndex, cResourceFood) * handicap;
			woodAmount = woodAmount + aiHCDeckGetCardValuePerResource(gDefaultDeck, cardIndex, cResourceWood) * handicap;
			goldAmount = goldAmount + aiHCDeckGetCardValuePerResource(gDefaultDeck, cardIndex, cResourceGold) * handicap;
		}
	}

	// Add resources from crates we currently haven't collected.
	for (i = 0; < numberCrates)
	{
		crateID = kbUnitQueryGetResult(crateQuery, i);
		foodAmount = foodAmount + kbUnitGetResourceAmount(crateID, cResourceFood) * handicap;
		woodAmount = woodAmount + kbUnitGetResourceAmount(crateID, cResourceWood) * handicap;
		goldAmount = goldAmount + kbUnitGetResourceAmount(crateID, cResourceGold) * handicap;
	}

	// Give our respective resource totals some oomph the highest priority plan that we cannot yet afford.
	if (foodAmount < highestPriPlanFoodNeeded)
		totalPlanFoodNeeded = totalPlanFoodNeeded + highestPriPlanFoodNeeded; // Add the plan again.
	if (woodAmount < highestPriPlanWoodNeeded)
		totalPlanWoodNeeded = totalPlanWoodNeeded + highestPriPlanWoodNeeded; // Add the plan again.
	if (goldAmount < highestPriPlanGoldNeeded)
		totalPlanGoldNeeded = totalPlanGoldNeeded + highestPriPlanGoldNeeded; // Add the plan again.

	// Check to see if the next shipment that we want to send has a cost. If so, account for it.
	// Be prepared to ship in 60 seconds.
	// if (kbTechCostPerResource(gNextShipmentTechID, cResourceFood) > 1.0)
	// 	totalPlanFoodNeeded = totalPlanFoodNeeded + kbTechCostPerResource(gNextShipmentTechID, cResourceFood) * (10.0 - 2 * kbGetAge());
	// if (kbTechCostPerResource(gNextShipmentTechID, cResourceWood) > 1.0)
	// 	totalPlanWoodNeeded = totalPlanWoodNeeded + kbTechCostPerResource(gNextShipmentTechID, cResourceWood) * (10.0 - 2 * kbGetAge());
	// if (kbTechCostPerResource(gNextShipmentTechID, cResourceGold) > 1.0)
	// 	totalPlanGoldNeeded = totalPlanGoldNeeded + kbTechCostPerResource(gNextShipmentTechID, cResourceGold) * (10.0 - 2 * kbGetAge());

	foodNeeded = totalPlanFoodNeeded - foodAmount;
	woodNeeded = totalPlanWoodNeeded - woodAmount;
	goldNeeded = totalPlanGoldNeeded - goldAmount;

	// For market trading.
	xsArraySetFloat(gResourceNeeds, cResourceFood, foodNeeded);
	xsArraySetFloat(gResourceNeeds, cResourceWood, woodNeeded);
	xsArraySetFloat(gResourceNeeds, cResourceGold, goldNeeded);

	if (foodNeeded < 0.0)
		foodNeeded = 0.0;
	if (woodNeeded < 0.0)
		woodNeeded = 0.0;
	if (goldNeeded < 0.0)
		goldNeeded = 0.0;

	// By using ratios, we will use the food as a baseline to adjust the percentages according to gather rate.
	woodNeeded = woodNeeded * (foodGatherRate / woodGatherRate);
	goldNeeded = goldNeeded * (foodGatherRate / goldGatherRate);
	totalNeeded = foodNeeded + woodNeeded + goldNeeded;

	// We have enough resource for our plans
	if (totalNeeded <= 0.0)
	{
		foodNeeded = 1.0;
		woodNeeded = foodGatherRate / woodGatherRate;
		goldNeeded = foodGatherRate / goldGatherRate;
		if (agingUp() && getAgingUpAge() == cAge2)
		{	// Force wood gathering when aging to Age 2 if we have nothing to do.
			foodNeeded = 0.1;
			woodNeeded = 0.8;
			goldNeeded = 0.1;
		}
		totalNeeded = foodNeeded + woodNeeded + goldNeeded;
	}

	foodPercentage = foodNeeded / totalNeeded;
	woodPercentage = woodNeeded / totalNeeded;
	goldPercentage = goldNeeded / totalNeeded;

	aiSetResourcePercentage(cResourceGold, false, goldPercentage);
	aiSetResourcePercentage(cResourceWood, false, woodPercentage);
	aiSetResourcePercentage(cResourceFood, false, foodPercentage);
	aiNormalizeResourcePercentages();   // Set them to 1.0 total, just in case these don't add up.
}

//==============================================================================
// getDedicatedGatherers
//
// For a specific resource, fetch the number of dedicated gatherers (i.e. static
// income from factories/banks/etc.), so that we will be able to account for
// this income in our villager rule.
//==============================================================================
int getDedicatedGatherers(int resourceType = -1)
{
	float temp = 0.0;
	int dedicatedVillagerValue = 0;
	int numBuildings = 0;
	float villagerGatherRate = 0.5;
	float dedicatedGatherRate = 0.0;
	float totalGatherRate = 0.0;
	float handicap = kbGetPlayerHandicap(cMyID);

	// TODO (James): Account for torps? Will likely disregard these and let the algorithm handle deficits.
	switch (resourceType)
	{
		case cResourceFood:
		{
			if (cMyCiv == cCivJapanese)
				villagerGatherRate = kbProtoUnitGetGatherRate(gEconUnit, cUnitTypeypBerryBuilding) * handicap;
			else
				villagerGatherRate = kbProtoUnitGetGatherRate(gEconUnit, cUnitTypeHuntable) * handicap;

			// Kancha Houses.
			if (cMyCiv == cCivDEInca)
			{
				numBuildings = kbUnitCount(cMyID, cUnitTypedeHouseInca, cUnitStateAlive);
				dedicatedGatherRate = 0.6 * numBuildings * handicap;
				if (kbTechGetStatus(cTechDEHCChichaBrewing) == cTechStatusActive)
					dedicatedGatherRate = dedicatedGatherRate * 1.5;
				totalGatherRate = totalGatherRate + dedicatedGatherRate;
			}

			break;
		}
		case cResourceWood:
		{
			villagerGatherRate = kbProtoUnitGetGatherRate(gEconUnit, cUnitTypeTree) * handicap;

			// Factories (should be on wood).
			numBuildings = kbUnitCount(cMyID, cUnitTypeFactory, cUnitStateAlive);
			dedicatedGatherRate = 5.5 * numBuildings * handicap;
			if (kbTechGetStatus(cTechFactoryWaterPower) == cTechStatusActive)
				dedicatedGatherRate = dedicatedGatherRate * 1.3;
			totalGatherRate = totalGatherRate + dedicatedGatherRate;

			// TODO (James): Account for animals on the shrines.
			// Shrines (should be on wood starting in Age 2; Age 1 food is negligible).
			if (cMyCiv == cCivJapanese && kbGetAge() >= cAge2)
			{
				numBuildings = kbUnitCount(cMyID, cUnitTypeypShrineJapanese, cUnitStateAlive);
				dedicatedGatherRate = 0.1 * numBuildings * handicap;
				if (kbTechGetStatus(cTechYPHCIncreasedTribute) == cTechStatusActive)
					dedicatedGatherRate = dedicatedGatherRate * 1.5;
				if (kbTechGetStatus(cTechypShrineFortressUpgrade) == cTechStatusActive)
					dedicatedGatherRate = dedicatedGatherRate * 4.0;
				totalGatherRate = totalGatherRate + dedicatedGatherRate;
			}

			break;
		}
		case cResourceGold:
		{
			if (cMyCiv == cCivXPIroquois || cMyCiv == cCivXPSioux)
				villagerGatherRate = kbProtoUnitGetGatherRate(gEconUnit, cUnitTypedeFurTrade) * handicap;
			else
				villagerGatherRate = kbProtoUnitGetGatherRate(gEconUnit, cUnitTypeAbstractMine) * handicap;

			// Banks.
			if (cMyCiv == cCivDutch || cMyCiv == cCivDEAmericans || cMyCiv == cCivJapanese)
			{
				numBuildings = kbUnitCount(cMyID, cUnitTypeBank, cUnitStateAlive);
				dedicatedGatherRate = 2.75 * numBuildings * handicap;
				if (kbTechGetStatus(cTechHCBetterBanks) == cTechStatusActive)
					dedicatedGatherRate = dedicatedGatherRate * 1.2;
				totalGatherRate = totalGatherRate + dedicatedGatherRate;
			}

			break;
		}
	}

	temp = totalGatherRate / villagerGatherRate;
	dedicatedVillagerValue = temp;

	return(dedicatedVillagerValue);
}

//==============================================================================
// findTradingLodge
//
// Find trading lodges to work for Haudenosaunee and Lakota. If we are lacking,
// build one.
//==============================================================================
int findTradingLodge(int resourceID = -1)
{
	vector location = kbUnitGetPosition(resourceID);
	int tradingLodge = getClosestUnit(cUnitTypedeFurTrade, cMyID, cUnitStateABQ, location, 15.0);
	if (tradingLodge >= 0)
	{
		return (tradingLodge);
	}

	if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypedeFurTrade) >= 0 ||
		((kbUnitCount(cMyID, cUnitTypedeFurTrade, cUnitStateABQ) * 10) > (gNumGoldVills + 1)))
	{
		return (-1);
	}

	// If we got here, tradingLodge < 0, so let's build one ASAP.
	int planID = aiPlanCreate("Trading Lodge Build Plan", cPlanBuild);
	aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, cUnitTypedeFurTrade);
	aiPlanSetVariableFloat(planID, cBuildPlanBuildingBufferSpace, 0, 6.0);
	aiPlanSetDesiredPriority(planID, 99);
	aiPlanSetDesiredResourcePriority(planID, 99);
	aiPlanSetEconomy(planID, true);
	aiPlanSetMilitary(planID, false);
	aiPlanSetEscrowID(planID, cRootEscrowID);
	aiPlanAddUnitType(planID, cUnitTypeLogicalTypeSettlerBuildLimit, 1, 1, 1);

	aiPlanSetVariableVector(planID, cBuildPlanCenterPosition, 0, location);
	aiPlanSetVariableFloat(planID, cBuildPlanCenterPositionDistance, 0, 30.0);
	aiPlanSetVariableVector(planID, cBuildPlanInfluencePosition, 0, location);
	aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionDistance, 0, 100.0);
	aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionValue, 0, 200.0);
	aiPlanSetVariableInt(planID, cBuildPlanInfluencePositionFalloff, 0, cBPIFalloffLinear);
	
	aiPlanSetVariableInt(planID, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypedeFurTrade);
	aiPlanSetVariableFloat(planID, cBuildPlanInfluenceUnitDistance, 0, 10.0);
	aiPlanSetVariableFloat(planID, cBuildPlanInfluenceUnitValue, 0, -20.0);
	aiPlanSetVariableInt(planID, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffLinear);

	aiPlanSetActive(planID);

	return (-1); // Should be -1.
}

//==============================================================================
// isUsableHuntTarget
//
// Validate animal food targets without rejecting positive-food carcasses.
//==============================================================================
bool isUsableHuntTarget(int targetID = -1)
{
	if (targetID < 0)
		return (false);
	if ((kbUnitIsType(targetID, cUnitTypeHuntable) == false) &&
		(kbUnitIsType(targetID, cUnitTypeHerdable) == false))
	{
		return (false);
	}
	if (kbUnitGetPosition(targetID) == cInvalidVector)
		return (false);
	if (kbUnitGetResourceAmount(targetID, cResourceFood) <= 0.0)
		return (false);

	return (true);
}

//==============================================================================
// Recoverable natural-resource validation.
//
// Behavioral recovery is deliberately limited to direct-task natural
// resources. Building-backed gathering, crates, fishing, and player-owned
// resource exchanges remain outside this path.
//==============================================================================
bool isRecoverableNaturalTargetClass(int targetID = -1, int actionID = -1)
{
	if (targetID < 0)
		return (false);

	if (actionID == cActionTypeHunting)
	{
		if (kbUnitIsType(targetID, cUnitTypeHuntable) ||
			kbUnitIsType(targetID, cUnitTypeHerdable))
		{
			return (true);
		}
		if ((kbUnitIsType(targetID, cUnitTypeTree) == true) &&
			(kbUnitIsType(targetID, cUnitTypeBuilding) == false) &&
			(kbUnitGetPlayerID(targetID) == 0))
		{
			return (true);
		}
		return (false);
	}

	if (actionID != cActionTypeGather)
		return (false);

	if ((kbUnitIsType(targetID, cUnitTypeAbstractFruit) == true) &&
		(kbUnitIsType(targetID, cUnitTypeBuilding) == false) &&
		(kbUnitIsType(targetID, cUnitTypeypGroveBuilding) == false) &&
		(kbUnitGetPlayerID(targetID) == 0))
	{
		return (true);
	}
	if ((kbUnitIsType(targetID, cUnitTypeAbstractMine) == true) &&
		(kbUnitIsType(targetID, cUnitTypeBuilding) == false) &&
		(kbUnitIsType(targetID, cUnitTypeAbstractResourceCrate) == false) &&
		(kbUnitGetPlayerID(targetID) == 0))
	{
		return (true);
	}
	return (false);
}

int getRecoverableNaturalTargetAction(int targetID = -1)
{
	if (isRecoverableNaturalTargetClass(targetID, cActionTypeHunting))
		return (cActionTypeHunting);
	if (isRecoverableNaturalTargetClass(targetID, cActionTypeGather))
		return (cActionTypeGather);
	return (-1);
}

int getRecoverableNaturalTargetKind(int targetID = -1, int actionID = -1)
{
	if (isRecoverableNaturalTargetClass(targetID, actionID) == false)
		return (-1);
	if (actionID == cActionTypeHunting)
	{
		if (kbUnitIsType(targetID, cUnitTypeTree))
			return (1); // Natural tree.
		return (0); // Huntable or herdable animal.
	}
	if (kbUnitIsType(targetID, cUnitTypeAbstractFruit))
		return (2); // Natural berry bush.
	return (3); // Natural mine.
}

int getRecoverableNaturalResourceType(int targetID = -1, int actionID = -1)
{
	int targetKind = getRecoverableNaturalTargetKind(targetID, actionID);
	if (targetKind < 0)
		return (-1);
	if (kbUnitGetPosition(targetID) == cInvalidVector)
		return (-1);

	if (targetKind == 0)
	{
		if (isUsableHuntTarget(targetID))
			return (cResourceFood);
		return (-1);
	}
	if (targetKind == 1)
	{
		if (kbUnitGetResourceAmount(targetID, cResourceWood) > 0.0)
			return (cResourceWood);
		return (-1);
	}
	if (targetKind == 2)
	{
		if (kbUnitGetResourceAmount(targetID, cResourceFood) > 0.0)
			return (cResourceFood);
		return (-1);
	}
	if (kbUnitGetResourceAmount(targetID, cResourceGold) > 0.0)
		return (cResourceGold);
	return (-1);
}

float getRecoverableNaturalTargetWorkDistance(int targetID = -1, int actionID = -1)
{
	if (getRecoverableNaturalTargetKind(targetID, actionID) == 3)
		return (5.0);
	return (3.0);
}

//==============================================================================
// Natural-target occupancy and admission helpers.
//
// Engine worker counts can omit villagers that are still moving toward, or
// otherwise logically targeting, a natural resource. Combine the engine count
// with raw villager targets. Animal orders also use short-lived assignment
// reservations so repeated taskVillagers passes do not overbook a hunt before
// the engine catches up.
//==============================================================================
int countVillagersTargetingResource(int targetID = -1, int actionID = -1)
{
	if ((targetID < 0) || (gVillagerQuery < 0))
		return (0);

	int numResults = kbUnitQueryNumberResults(gVillagerQuery);
	int count = 0;
	int index = -1;
	int unitID = -1;
	for (index = 0; < numResults)
	{
		unitID = kbUnitQueryGetResult(gVillagerQuery, index);
		if ((kbUnitGetActionType(unitID) == actionID) &&
			(kbUnitGetTargetUnitID(unitID) == targetID))
		{
			count++;
		}
	}
	return (count);
}

int getResourceTargetEngineWorkerCount(int targetID = -1)
{
	if (targetID < 0)
		return (0);

	int ownerID = kbUnitGetPlayerID(targetID);
	if (ownerID < 0)
		ownerID = cMyID;

	xsSetContextPlayer(ownerID);
	int count = kbUnitGetNumberWorkers(targetID);
	xsSetContextPlayer(cMyID);
	if (count < 0)
		count = 0;
	return (count);
}

int manageHuntAssignmentReservations(int targetID = -1, int unitID = -1, int now = -1)
{
	const int cHuntReservationCapacity = 200;
	const int cHuntReservationInterval = 30000;

	static int reservationUnits = -1;
	static int reservationTargets = -1;
	static int reservationTimes = -1;

	if (targetID < 0)
		return (0);
	if (now < 0)
		now = xsGetTime();

	if (reservationUnits < 0)
	{
		reservationUnits =
			xsArrayCreateInt(cHuntReservationCapacity, -1, "Hunt reservation units");
		reservationTargets =
			xsArrayCreateInt(cHuntReservationCapacity, -1, "Hunt reservation targets");
		reservationTimes =
			xsArrayCreateInt(cHuntReservationCapacity, -1, "Hunt reservation times");
	}

	int index = -1;
	int trackedUnitID = -1;
	int trackedTargetID = -1;
	int trackedTime = -1;
	int elapsed = -1;
	int emptyIndex = -1;
	int oldestIndex = 0;
	int oldestTime = now;

	if (unitID >= 0)
	{
		for (index = 0; < cHuntReservationCapacity)
		{
			trackedUnitID = xsArrayGetInt(reservationUnits, index);
			trackedTime = xsArrayGetInt(reservationTimes, index);
			if (trackedUnitID == unitID)
			{
				emptyIndex = index;
				break;
			}
			if ((trackedUnitID < 0) && (emptyIndex < 0))
				emptyIndex = index;
			if (trackedTime < oldestTime)
			{
				oldestTime = trackedTime;
				oldestIndex = index;
			}
		}

		if (emptyIndex < 0)
			emptyIndex = oldestIndex;
		xsArraySetInt(reservationUnits, emptyIndex, unitID);
		xsArraySetInt(reservationTargets, emptyIndex, targetID);
		xsArraySetInt(reservationTimes, emptyIndex, now);
		return (0);
	}

	int count = 0;
	for (index = 0; < cHuntReservationCapacity)
	{
		trackedUnitID = xsArrayGetInt(reservationUnits, index);
		trackedTargetID = xsArrayGetInt(reservationTargets, index);
		trackedTime = xsArrayGetInt(reservationTimes, index);
		if ((trackedUnitID < 0) || (trackedTargetID != targetID) || (trackedTime < 0))
			continue;

		elapsed = now - trackedTime;
		if (elapsed >= cHuntReservationInterval)
		{
			xsArraySetInt(reservationUnits, index, -1);
			xsArraySetInt(reservationTargets, index, -1);
			xsArraySetInt(reservationTimes, index, -1);
			continue;
		}

		// A Hunting/raw-target pair already contributes to
		// countVillagersTargetingResource(). Other actions remain pending.
		if ((kbUnitGetActionType(trackedUnitID) != cActionTypeHunting) ||
			(kbUnitGetTargetUnitID(trackedUnitID) != targetID))
			count++;
	}
	return (count);
}

int getResourceTargetLogicalWorkerCount(int targetID = -1, int actionID = -1,
	int now = -1)
{
	int engineWorkers = getResourceTargetEngineWorkerCount(targetID);
	int rawWorkers = countVillagersTargetingResource(targetID, actionID);
	int logicalWorkers = engineWorkers;
	if (rawWorkers > logicalWorkers)
		logicalWorkers = rawWorkers;
	if ((actionID == cActionTypeHunting) &&
		(kbUnitIsType(targetID, cUnitTypeHuntable) ||
		kbUnitIsType(targetID, cUnitTypeHerdable)))
	{
		logicalWorkers += manageHuntAssignmentReservations(targetID, -1, now);
	}
	return (logicalWorkers);
}

int manageGathererRecoveryPressure(int targetID = -1, bool recordRecovery = false,
	int now = -1)
{
	const int cGathererPressureCapacity = 64;
	const int cGathererPressureWindow = 30000;
	const int cGathererPressureInterval = 30000;

	static int pressureTargets = -1;
	static int pressureCounts = -1;
	static int pressureLastRecoveryTimes = -1;
	static int pressureUntilTimes = -1;
	static int latestPressureUntil = -1;

	if (targetID < 0)
		return (0);
	if (now < 0)
		now = xsGetTime();
	// In the normal case no target is under pressure. Avoid scanning the
	// bounded table from every candidate-capacity check until a penalty exists.
	if ((recordRecovery == false) &&
		((latestPressureUntil < 0) || (latestPressureUntil <= now)))
	{
		return (0);
	}
	if (pressureTargets < 0)
	{
		pressureTargets =
			xsArrayCreateInt(cGathererPressureCapacity, -1, "Gather pressure targets");
		pressureCounts =
			xsArrayCreateInt(cGathererPressureCapacity, 0, "Gather pressure counts");
		pressureLastRecoveryTimes =
			xsArrayCreateInt(cGathererPressureCapacity, -1, "Gather pressure recovery times");
		pressureUntilTimes =
			xsArrayCreateInt(cGathererPressureCapacity, -1, "Gather pressure until times");
	}

	int pressureIndex = -1;
	int emptyIndex = -1;
	int oldestIndex = 0;
	int oldestTime = now;
	int index = -1;
	int trackedTargetID = -1;
	int trackedRecoveryTime = -1;
	for (index = 0; < cGathererPressureCapacity)
	{
		trackedTargetID = xsArrayGetInt(pressureTargets, index);
		trackedRecoveryTime = xsArrayGetInt(pressureLastRecoveryTimes, index);
		if (trackedTargetID == targetID)
		{
			pressureIndex = index;
			break;
		}
		if ((trackedTargetID < 0) && (emptyIndex < 0))
			emptyIndex = index;
		if (trackedRecoveryTime < oldestTime)
		{
			oldestTime = trackedRecoveryTime;
			oldestIndex = index;
		}
	}

	if (pressureIndex < 0)
	{
		if (recordRecovery == false)
			return (0);
		pressureIndex = emptyIndex;
		if (pressureIndex < 0)
			pressureIndex = oldestIndex;
		xsArraySetInt(pressureTargets, pressureIndex, targetID);
		xsArraySetInt(pressureCounts, pressureIndex, 0);
		xsArraySetInt(pressureLastRecoveryTimes, pressureIndex, -1);
		xsArraySetInt(pressureUntilTimes, pressureIndex, -1);
	}

	if (recordRecovery == true)
	{
		int recoveryCount = 1;
		trackedRecoveryTime =
			xsArrayGetInt(pressureLastRecoveryTimes, pressureIndex);
		if ((trackedRecoveryTime >= 0) &&
			((now - trackedRecoveryTime) < cGathererPressureWindow))
		{
			recoveryCount = xsArrayGetInt(pressureCounts, pressureIndex) + 1;
		}
		xsArraySetInt(pressureCounts, pressureIndex, recoveryCount);
		xsArraySetInt(pressureLastRecoveryTimes, pressureIndex, now);
		if (recoveryCount >= 2)
		{
			xsArraySetInt(pressureUntilTimes, pressureIndex,
				now + cGathererPressureInterval);
			if ((now + cGathererPressureInterval) > latestPressureUntil)
				latestPressureUntil = now + cGathererPressureInterval;
		}
	}

	if (xsArrayGetInt(pressureUntilTimes, pressureIndex) > now)
		return (1);
	return (0);
}

int getRecoveryAdjustedCapacity(int targetID = -1, int normalCapacity = -1,
	int now = -1)
{
	if (normalCapacity < 1)
		return (0);
	if (manageGathererRecoveryPressure(targetID, false, now) > 0)
	{
		normalCapacity--;
		if (normalCapacity < 1)
			normalCapacity = 1;
	}
	return (normalCapacity);
}

int getHuntTargetWorkerCapacity(int targetID = -1, bool liveWildHunt = false,
	int maximumCapacity = 5, int now = -1)
{
	const float cHuntFoodPerWorker = 50.0;

	if ((isUsableHuntTarget(targetID) == false) || (maximumCapacity < 1))
		return (0);
	if (liveWildHunt == true)
	{
		int liveCapacity = 2;
		if (liveCapacity > maximumCapacity)
			liveCapacity = maximumCapacity;
		return (getRecoveryAdjustedCapacity(targetID, liveCapacity, now));
	}

	float foodAmount = kbUnitGetResourceAmount(targetID, cResourceFood);
	int capacity = 1;
	if (foodAmount > cHuntFoodPerWorker)
		capacity = 2;
	if (foodAmount > (2.0 * cHuntFoodPerWorker))
		capacity = 3;
	if (foodAmount > (3.0 * cHuntFoodPerWorker))
		capacity = 4;
	if (foodAmount > (4.0 * cHuntFoodPerWorker))
		capacity = 5;
	if (capacity > maximumCapacity)
		capacity = maximumCapacity;
	return (getRecoveryAdjustedCapacity(targetID, capacity, now));
}

int getRecoverableNaturalTargetWorkerCapacity(int targetID = -1, int now = -1)
{
	int actionID = getRecoverableNaturalTargetAction(targetID);
	int targetKind = getRecoverableNaturalTargetKind(targetID, actionID);
	if (getRecoverableNaturalResourceType(targetID, actionID) < 0)
		return (0);

	if (targetKind == 0)
	{
		if (kbUnitGetCurrentHitpoints(targetID) > 0.0)
		{
			int liveCapacity = 5;
			if ((kbUnitIsType(targetID, cUnitTypeHuntable) == true) &&
				(kbUnitIsType(targetID, cUnitTypeHerdable) == false))
			{
				liveCapacity = 2;
			}
			return (getRecoveryAdjustedCapacity(targetID, liveCapacity, now));
		}

		int carcassMaximumCapacity = 5;
		if (kbUnitIsType(targetID, cUnitTypeHerdable))
			carcassMaximumCapacity = 4;
		return (getHuntTargetWorkerCapacity(targetID, false,
			carcassMaximumCapacity, now));
	}
	if ((targetKind == 1) || (targetKind == 2))
		return (getRecoveryAdjustedCapacity(targetID, 5, now));
	if (targetKind == 3)
		return (getRecoveryAdjustedCapacity(targetID, 20, now));
	return (0);
}

bool shouldReportHuntAssignment(int targetID = -1, int decisionID = -1, int now = -1)
{
	const int cHuntAssignmentTraceCapacity = 64;
	const int cHuntAssignmentTraceInterval = 5000;

	static int assignmentTargets = -1;
	static int assignmentDecisions = -1;
	static int assignmentTimes = -1;

	if ((targetID < 0) || (decisionID < 0))
		return (false);
	if (assignmentTargets < 0)
	{
		assignmentTargets =
			xsArrayCreateInt(cHuntAssignmentTraceCapacity, -1, "Hunt assignment targets");
		assignmentDecisions =
			xsArrayCreateInt(cHuntAssignmentTraceCapacity, -1, "Hunt assignment decisions");
		assignmentTimes =
			xsArrayCreateInt(cHuntAssignmentTraceCapacity, -1, "Hunt assignment times");
	}

	int emptyIndex = -1;
	int oldestIndex = 0;
	int oldestTime = now;
	int index = -1;
	int trackedTargetID = -1;
	int trackedDecisionID = -1;
	int trackedTime = -1;
	int elapsed = -1;
	for (index = 0; < cHuntAssignmentTraceCapacity)
	{
		trackedTargetID = xsArrayGetInt(assignmentTargets, index);
		trackedDecisionID = xsArrayGetInt(assignmentDecisions, index);
		trackedTime = xsArrayGetInt(assignmentTimes, index);
		if ((trackedTargetID == targetID) && (trackedDecisionID == decisionID))
		{
			elapsed = now - trackedTime;
			if ((trackedTime >= 0) && (elapsed < cHuntAssignmentTraceInterval))
				return (false);
			xsArraySetInt(assignmentTimes, index, now);
			return (true);
		}
		if ((trackedTargetID < 0) && (emptyIndex < 0))
			emptyIndex = index;
		if (trackedTime < oldestTime)
		{
			oldestTime = trackedTime;
			oldestIndex = index;
		}
	}

	if (emptyIndex < 0)
		emptyIndex = oldestIndex;
	xsArraySetInt(assignmentTargets, emptyIndex, targetID);
	xsArraySetInt(assignmentDecisions, emptyIndex, decisionID);
	xsArraySetInt(assignmentTimes, emptyIndex, now);
	return (true);
}

void traceHuntAssignment(int unitID = -1, int targetID = -1, bool liveTarget = false,
	int capacity = -1, int decisionID = -1, string decision = "")
{
	if ((gBetterAIDebug < 1) && (cDebugEconomy == false))
		return;
	if (targetID < 0)
		return;

	int now = xsGetTime();
	int engineWorkers = getResourceTargetEngineWorkerCount(targetID);
	int rawWorkers =
		countVillagersTargetingResource(targetID, cActionTypeHunting);
	int pendingWorkers = manageHuntAssignmentReservations(targetID, -1, now);
	int logicalWorkers = engineWorkers;
	if (rawWorkers > logicalWorkers)
		logicalWorkers = rawWorkers;
	logicalWorkers += pendingWorkers;
	int pressureActive =
		manageGathererRecoveryPressure(targetID, false, now);
	int traceDecisionID = decisionID * 100 + logicalWorkers +
		(pressureActive * 50);
	if (shouldReportHuntAssignment(targetID, traceDecisionID, now) == false)
		return;

	debugEvent("ECO-ASSIGN", "u=" + unitID + " t=" + targetID +
		" live=" + (liveTarget ? "1" : "0") +
		" food=" + kbUnitGetResourceAmount(targetID, cResourceFood) +
		" engine=" + engineWorkers + " raw=" + rawWorkers +
		" pending=" + pendingWorkers + " used=" + logicalWorkers +
		" cap=" + capacity + " pressure=" + pressureActive +
		" decision=" + decision);
}

//==============================================================================
// updateFoodBreakdown
//
// Populate an array with food resources that should be gathered.
//==============================================================================
void updateFoodBreakdown(void)
{
	arrayResetSelf(gFoodResources);
	arrayResetSelf(gDecayingAnimals);
	arrayResetSelf(gFoodNumWorkers);
	arrayResetSelf(gDecayingNumWorkers);
	arrayResetSelf(gMaxFoodWorkers);

	int numberResults = 0;
	// Get a rough estimate on our food supply in terms of how many villagers
	// I allow to gather from the particular resource multiplied by 0.8.
	// If by the end totalResourceWorth is not enough, then we should prepare
	// to build a Mill type. Made a float for certain calculations.
	float resourceWorth = 0.0;
	float totalResourceWorth = 0.0;
	int resourceID = -1;
	int planID = -1;
	int numWorkers = -1;
	int maxWorkers = -1;
	int now = xsGetTime();
	int temp = -1;

	// Search for food.
	if (gFoodQuery < 0)
	{
		gFoodQuery = kbUnitQueryCreate("Food Resources Query");
		kbUnitQuerySetIgnoreKnockedOutUnits(gFoodQuery, true);
		kbUnitQuerySetSeeableOnly(gFoodQuery, false);
		kbUnitQuerySetPosition(gFoodQuery, gHomeBase);
		kbUnitQuerySetAreaGroupID(gFoodQuery, kbAreaGroupGetIDByPosition(gHomeBase));
	}
	kbUnitQuerySetMaximumDistance(gFoodQuery, 120.0);
	kbUnitQueryResetResults(gFoodQuery);

	// Herdables.
	if (cMyCiv != cCivJapanese && cMyCiv != cCivIndians &&
		civIsAfrican() == false && totalResourceWorth < gNumFoodVills)
	{	// Decaying.
		kbUnitQuerySetUnitType(gFoodQuery, cUnitTypeHerdable);
		kbUnitQuerySetPlayerID(gFoodQuery, 0, false);
		kbUnitQuerySetSeeableOnly(gFoodQuery, true);
		kbUnitQuerySetActionType(gFoodQuery, cActionTypeDeath);
		numberResults = kbUnitQueryExecute(gFoodQuery);

		for (i = 0; < numberResults)
		{
			resourceID = kbUnitQueryGetResult(gFoodQuery, i);

			if (isUsableHuntTarget(resourceID) == false)
				continue;
			if (resourceCloserToAlly(resourceID))
				continue;

			numWorkers = getResourceTargetLogicalWorkerCount(
				resourceID, cActionTypeHunting, now);
			maxWorkers = getHuntTargetWorkerCapacity(
				resourceID, false, 4, now);
			if (numWorkers >= maxWorkers)
			{
				traceHuntAssignment(-1, resourceID, false, maxWorkers, 1, "full");
				// Still count it because we are gathering it.
				resourceWorth = resourceWorth + 1;
				continue;
			}

			arrayPushInt(gDecayingAnimals, resourceID);
			arrayPushInt(gDecayingNumWorkers, numWorkers);
			resourceWorth = resourceWorth + 1;
		}

		kbUnitQueryResetResults(gFoodQuery);

		// Live.
		kbUnitQuerySetPlayerID(gFoodQuery, cMyID, false);
		kbUnitQuerySetActionType(gFoodQuery, -1);
		kbUnitQuerySetSeeableOnly(gFoodQuery, false);
		kbUnitQuerySetState(gFoodQuery, cUnitStateAlive);
		numberResults = kbUnitQueryExecute(gFoodQuery);

		for (i = 0; < numberResults)
		{
			resourceID = kbUnitQueryGetResult(gFoodQuery, i);

			if (isUsableHuntTarget(resourceID) == false)
				continue;
			// Avoid unfattened animals.
			if (kbUnitGetResourceAmount(resourceID, cResourceFood) <
				kbUnitGetCarryCapacity(resourceID, cResourceFood))
				continue;

			// Avoid animals on shrines. Probably will always be false as
			// since they are our herdables, they must be on our shrines, which would
			// make us Japanese -- not even in this conditional statement.
			xsSetContextPlayer(0);
			temp = kbUnitGetTargetUnitID(resourceID);
			xsSetContextPlayer(cMyID);
			if (kbUnitIsType(temp, cUnitTypeypShrineJapanese) == true ||
				kbUnitIsType(temp, cUnitTypeypWJToshoguShrine2) == true ||
				kbUnitIsType(temp, cUnitTypeypWJToshoguShrine3) == true ||
				kbUnitIsType(temp, cUnitTypeypWJToshoguShrine4) == true ||
				kbUnitIsType(temp, cUnitTypeypWJToshoguShrine5) == true)
			{
				continue;
			}

			numWorkers = getResourceTargetLogicalWorkerCount(
				resourceID, cActionTypeHunting, now);
			maxWorkers = getRecoveryAdjustedCapacity(resourceID, 5, now);
			if (numWorkers >= maxWorkers)
			{
				traceHuntAssignment(-1, resourceID, true, maxWorkers, 1, "full");
				resourceWorth = resourceWorth + 1;
				continue;
			}

			arrayPushInt(gFoodResources, resourceID);
			arrayPushInt(gFoodNumWorkers, numWorkers);
			arrayPushInt(gMaxFoodWorkers, 5);
			resourceWorth = resourceWorth + 1;
		}

		totalResourceWorth += resourceWorth;
		// Reset for other queries.
		resourceWorth = 0.0;
		kbUnitQueryResetResults(gFoodQuery);
	}

	// Huntables.
	if (cMyCiv != cCivJapanese && totalResourceWorth < gNumFoodVills)
	{	// Decaying
		kbUnitQuerySetUnitType(gFoodQuery, cUnitTypeHuntable);
		kbUnitQuerySetPlayerID(gFoodQuery, 0, false);
		kbUnitQuerySetActionType(gFoodQuery, cActionTypeDeath);
		kbUnitQuerySetSeeableOnly(gFoodQuery, true);
		kbUnitQuerySetState(gFoodQuery, cUnitStateAny);
		numberResults = kbUnitQueryExecute(gFoodQuery);

		for (i = 0; < numberResults)
		{
			resourceID = kbUnitQueryGetResult(gFoodQuery, i);

			if (isUsableHuntTarget(resourceID) == false)
				continue;
			if (resourceCloserToAlly(resourceID))
				continue;

			numWorkers = getResourceTargetLogicalWorkerCount(
				resourceID, cActionTypeHunting, now);
			maxWorkers = getHuntTargetWorkerCapacity(
				resourceID, false, 5, now);
			if (numWorkers >= maxWorkers)
			{
				traceHuntAssignment(-1, resourceID, false, maxWorkers, 1, "full");
				// Still count it because we are gathering it.
				resourceWorth = resourceWorth + 1;
				continue;
			}

			if (getDistance(kbUnitGetPosition(resourceID), gHomeBase) > 45)
			{
				if (getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia,
					cUnitStateAlive, kbUnitGetPosition(resourceID), 45.0) > 2)
					continue;
			}

			arrayPushInt(gDecayingAnimals, resourceID);
			arrayPushInt(gDecayingNumWorkers, numWorkers);
			resourceWorth = resourceWorth + 1;
		}

		kbUnitQueryResetResults(gFoodQuery);

		// Live
		kbUnitQuerySetActionType(gFoodQuery, -1);
		kbUnitQuerySetState(gFoodQuery, cUnitStateAlive);
		kbUnitQuerySetSeeableOnly(gFoodQuery, false);
		numberResults = kbUnitQueryExecute(gFoodQuery);

		for (i = 0; < numberResults)
		{
			resourceID = kbUnitQueryGetResult(gFoodQuery, i);

			if (isUsableHuntTarget(resourceID) == false)
				continue;
			if (resourceCloserToAlly(resourceID))
				continue;

			// Avoid animals on shrines.
			xsSetContextPlayer(0);
			temp = kbUnitGetTargetUnitID(resourceID);
			xsSetContextPlayer(cMyID);
			if (kbUnitIsType(temp, cUnitTypeypShrineJapanese) == true ||
				kbUnitIsType(temp, cUnitTypeypWJToshoguShrine2) == true ||
				kbUnitIsType(temp, cUnitTypeypWJToshoguShrine3) == true ||
				kbUnitIsType(temp, cUnitTypeypWJToshoguShrine4) == true ||
				kbUnitIsType(temp, cUnitTypeypWJToshoguShrine5) == true)
			{
				continue;
			}

			if (getDistance(kbUnitGetPosition(resourceID), gHomeBase) > 45)
			{
				if (getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia,
					cUnitStateAlive, kbUnitGetPosition(resourceID), 45.0) > 2)
					continue;
			}

			// Admit up to two villagers to herd/kill a live wild animal. Once it
			// becomes a carcass, the decaying path admits workers according to
			// its remaining food.
			numWorkers = getResourceTargetLogicalWorkerCount(
				resourceID, cActionTypeHunting, now);
			maxWorkers = getHuntTargetWorkerCapacity(
				resourceID, true, 2, now);
			if (numWorkers >= maxWorkers)
			{
				traceHuntAssignment(-1, resourceID, true, maxWorkers, 1, "full");
				resourceWorth = resourceWorth + 1;
				continue;
			}

			arrayPushInt(gFoodResources, resourceID);
			arrayPushInt(gFoodNumWorkers, numWorkers);
			arrayPushInt(gMaxFoodWorkers, 2);
			resourceWorth = resourceWorth + 1;
		}

		resourceWorth = resourceWorth * 4; // Count a Huntable as 4 villagers.
		totalResourceWorth += resourceWorth;
		// Reset for other queries.
		resourceWorth = 0.0;
		kbUnitQueryResetResults(gFoodQuery);
	}

	// Cherry Orchards.
	if (totalResourceWorth < gNumFoodVills)
	{
		kbUnitQuerySetMaximumDistance(gFoodQuery, -1);
		kbUnitQuerySetPlayerID(gFoodQuery, cMyID, false);
		kbUnitQuerySetState(gFoodQuery, cUnitStateAlive);
		kbUnitQuerySetUnitType(gFoodQuery, cUnitTypeypBerryBuilding);
		numberResults = kbUnitQueryExecute(gFoodQuery);

		for (i = 0; < numberResults)
		{
			resourceID = kbUnitQueryGetResult(gFoodQuery, i);

			// Too many current gatherers on an Orchard.
			numWorkers = kbUnitGetNumberWorkers(resourceID);
			if (numWorkers >= 28)
			{	// Still count it because we are gathering it.
				resourceWorth = resourceWorth + 1;
				continue;
			}

			arrayPushInt(gFoodResources, resourceID);
			arrayPushInt(gFoodNumWorkers, numWorkers);
			arrayPushInt(gMaxFoodWorkers, 28);
			resourceWorth = resourceWorth + 1;
		}
		resourceWorth = resourceWorth * 21; // Count a cherry orchard as 21 villagers.
		totalResourceWorth += resourceWorth;
		// Reset for other queries.
		resourceWorth = 0.0;
		kbUnitQueryResetResults(gFoodQuery);
	}

	// Berry types.
	if (totalResourceWorth < gNumFoodVills)
	{
		kbUnitQuerySetMaximumDistance(gFoodQuery, 120.0);
		kbUnitQuerySetPlayerID(gFoodQuery, 0, false);
		kbUnitQuerySetState(gFoodQuery, cUnitStateAny);
		kbUnitQuerySetUnitType(gFoodQuery, cUnitTypeAbstractFruit);
		kbUnitQueryExecute(gFoodQuery);
		numberResults = kbUnitQueryNumberResults(gFoodQuery);

		for (i = 0; < numberResults)
		{
			resourceID = kbUnitQueryGetResult(gFoodQuery, i);

			// Admit only valid Gaia berry bushes. Mango Groves, Torp bushes,
			// and other building/player-owned fruit targets stay outside this
			// natural-resource path.
			if (getRecoverableNaturalResourceType(
				resourceID, cActionTypeGather) != cResourceFood)
				continue;

			if (resourceCloserToAlly(resourceID))
				continue;

			// Too many current gatherers on Berry Bushes.
			numWorkers = getResourceTargetLogicalWorkerCount(
				resourceID, cActionTypeGather, now);
			maxWorkers = getRecoveryAdjustedCapacity(resourceID, 5, now);
			if (numWorkers >= maxWorkers)
			{
				// Still count it because we are gathering it.
				resourceWorth = resourceWorth + 1;
				continue;
			}

			if (getDistance(kbUnitGetPosition(resourceID), gHomeBase) > 45)
			{
				if (getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia,
					cUnitStateAlive, kbUnitGetPosition(resourceID), 45.0) > 2)
					continue;
			}

			arrayPushInt(gFoodResources, resourceID);
			arrayPushInt(gFoodNumWorkers, numWorkers);
			arrayPushInt(gMaxFoodWorkers, 5);
			resourceWorth = resourceWorth + 1;
		}

		resourceWorth = resourceWorth * 4; // Count a cherry orchard as 21 villagers.
		totalResourceWorth += resourceWorth;
		// Reset for other queries.
		resourceWorth = 0.0;
		kbUnitQueryResetResults(gFoodQuery);
	}

	// Mills/Farms/Paddies/Fields.
	if (totalResourceWorth < gNumFoodVills || kbGetAge() >= cAge4)
	{
		kbUnitQuerySetMaximumDistance(gFoodQuery, -1);
		kbUnitQuerySetPlayerID(gFoodQuery, cMyID, false);
		kbUnitQuerySetState(gFoodQuery, cUnitStateABQ);
		kbUnitQuerySetUnitType(gFoodQuery, gFarmUnit);
		kbUnitQueryExecute(gFoodQuery);
		numberResults = kbUnitQueryNumberResults(gFoodQuery);
		int maxNumWorkers = 10;

		for (i = 0; < numberResults)
		{
			resourceID = kbUnitQueryGetResult(gFoodQuery, i);
			numWorkers = kbUnitGetNumberWorkers(resourceID);
			maxNumWorkers = 10;

			// Field on Gold or maxed out.
			if (kbUnitIsType(resourceID, cUnitTypedeField))
			{
				if (aiUnitGetTactic(resourceID) == cTacticFieldCoin)
					continue;
				else if (numWorkers >= 3)
				{	// Still count it because we are gathering it.
					resourceWorth = resourceWorth + 1;
					continue;
				}
				maxNumWorkers = 3;
			}
			// Paddy on Gold or maxed out.
			else if (kbUnitIsType(resourceID, cUnitTypeypRicePaddy))
			{
				if (aiUnitGetTactic(resourceID) == cTacticPaddyCoin)
					continue;
				else if (numWorkers >= 10)
				{	// Still count it because we are gathering it.
					resourceWorth = resourceWorth + 1;
					continue;
				}
			}
			// Hacienda on Gold or maxed out.
			else if (kbUnitIsType(resourceID, cUnitTypedeHacienda))
			{
				if (aiUnitGetTactic(resourceID) == cTacticHaciendaCoin)
					continue;
				else if (numWorkers >= 20)
				{	// Still count it because we are gathering it.
					resourceWorth = resourceWorth + 1;
					continue;
				}
				maxNumWorkers = 20;
			}
			// Mill/Farm maxed out.
			else if (numWorkers >= 10)
			{	// Still count it because we are gathering it.
				resourceWorth = resourceWorth + 1;
				continue;
			}

			arrayPushInt(gFoodResources, resourceID);
			arrayPushInt(gFoodNumWorkers, numWorkers);
			arrayPushInt(gMaxFoodWorkers, maxNumWorkers);
			resourceWorth = resourceWorth + 1;
		}

		if (civIsAfrican() == true)
			resourceWorth = resourceWorth * 2.7; // Count a Food Field as 2.7 villagers.
		else if (cMyCiv == cCivDEMexicans)
			resourceWorth = resourceWorth * 18; // Count a Food Hacienda as 18 villagers.
		else
			resourceWorth = resourceWorth * 9; // Count a Mill/Farm/Food Paddy as 9 villagers.

		totalResourceWorth += resourceWorth;
		// Reset of the query is unecessary as the rule will reset it when it runs again.
	}

	// Basically, if we have reached this point, we should probably build a food-producing
	// building because we do not want to run out of gold resources.
	int millWorth = 10;
	int maxPlans = 4;
	if (cMyCiv == cCivDEMexicans)
	{
		millWorth = 20;
		maxPlans = 2;
	}
	else if (civIsAfrican() == true)
	{
		millWorth = 3;
		maxPlans = 8;
	}

	if (totalResourceWorth < gNumFoodVills && kbGetAge() >= cAge3)
	{
		arrayRemoveDonePlans(gMillTypePlans);
		if (arrayGetSize(gMillTypePlans) < maxPlans)
		{
			if (gNumFoodVills - totalResourceWorth > millWorth * arrayGetSize(gMillTypePlans))
			{
				planID = addMillBuildPlan();
				if (planID >= 0)
				{
					arrayPushInt(gMillTypePlans, planID);
					aiPlanSetDesiredPriority(planID, 99);
					aiPlanSetDesiredResourcePriority(planID, 99);
				}
			}
		}
	}
}

//==============================================================================
// updateWoodBreakdown
//
// Populate an array with wood resources that should be gathered.
//==============================================================================
void updateWoodBreakdown(void)
{
	arrayResetSelf(gWoodResources);
	arrayResetSelf(gWoodNumWorkers);

	int numberResults = 0;
	int resourceID = -1;
	int planID = -1;
	int numWorkers = -1;
	int maxWorkers = 5;
	int now = xsGetTime();

	if (gWoodQuery < 0)
	{
		gWoodQuery = kbUnitQueryCreate("Wood Resources Query");
		kbUnitQuerySetPlayerID(gWoodQuery, -1, false);
		kbUnitQuerySetPlayerRelation(gWoodQuery, cPlayerRelationAny);
		kbUnitQuerySetIgnoreKnockedOutUnits(gWoodQuery, true);
		kbUnitQuerySetPosition(gWoodQuery, gHomeBase);
		kbUnitQuerySetAreaGroupID(gWoodQuery, kbAreaGroupGetIDByPosition(gHomeBase));
		kbUnitQuerySetAscendingSort(gWoodQuery, true);
		kbUnitQuerySetMaximumDistance(gWoodQuery, 200.0);
	}
	kbUnitQueryResetResults(gWoodQuery);

	if (numberResults < gNumWoodVills)
	{
		kbUnitQuerySetPlayerID(gWoodQuery, 0, false);
		kbUnitQuerySetUnitType(gWoodQuery, cUnitTypeWood);
		kbUnitQuerySetState(gWoodQuery, cUnitStateAlive);
		kbUnitQuerySetSeeableOnly(gWoodQuery, false);
		kbUnitQueryExecute(gWoodQuery);

		kbUnitQuerySetUnitType(gWoodQuery, cUnitTypeTree);
		kbUnitQuerySetState(gWoodQuery, cUnitStateDead);
		kbUnitQuerySetSeeableOnly(gWoodQuery, true);
		kbUnitQueryExecute(gWoodQuery);

		kbUnitQuerySetPlayerID(gWoodQuery, cMyID, false);
		kbUnitQuerySetUnitType(gWoodQuery, cUnitTypeypGroveBuilding);
		kbUnitQuerySetState(gWoodQuery, cUnitStateAlive);
		kbUnitQuerySetSeeableOnly(gWoodQuery, false);
		kbUnitQueryExecute(gWoodQuery);
		numberResults = kbUnitQueryNumberResults(gWoodQuery);

		for (i = 0; < numberResults)
		{
			resourceID = kbUnitQueryGetResult(gWoodQuery, i);

			maxWorkers = 5;
			if (kbUnitIsType(resourceID, cUnitTypeypGroveBuilding))
			{
				numWorkers = getResourceTargetEngineWorkerCount(resourceID);
				maxWorkers = 25;
			}
			else if (kbUnitIsType(resourceID, cUnitTypeTree))
			{
				if (getRecoverableNaturalResourceType(
					resourceID, cActionTypeHunting) != cResourceWood)
				{
					continue;
				}
				numWorkers = getResourceTargetLogicalWorkerCount(
					resourceID, cActionTypeHunting, now);
				maxWorkers =
					getRecoveryAdjustedCapacity(resourceID, 5, now);
			}
			else
			{
				// This helper switches to the target owner only for the worker
				// count and always restores cMyID before returning.
				numWorkers = getResourceTargetEngineWorkerCount(resourceID);
			}

			// Too many current gatherers.
			if (numWorkers >= maxWorkers)
				continue;

			if (getDistance(kbUnitGetPosition(resourceID), gHomeBase) > 45)
			{
				if (getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia,
					cUnitStateAlive, kbUnitGetPosition(resourceID), 45.0) > 2)
					continue;
			}

			arrayPushInt(gWoodResources, resourceID);
			arrayPushInt(gWoodNumWorkers, numWorkers);
		}
		// Reset of the query is unecessary as the rule will reset it when it runs again.
	}
}

//==============================================================================
// updateGoldBreakdown
//
// Populate an array with gold resources that should be gathered.
//==============================================================================
void updateGoldBreakdown(void)
{
	arrayResetSelf(gGoldResources);
	arrayResetSelf(gGoldNumWorkers);
	arrayResetSelf(gMaxGoldWorkers);

	int numberResults = 0;
	float resourceWorth = 0.0;
	float totalResourceWorth = 0.0;
	int resourceID = -1;
	int tradingLodge = -1;
	int planID = -1;
	int numWorkers = -1;
	int maxWorkers = 20;
	int now = xsGetTime();

	if (gGoldQuery < 0)
	{
		gGoldQuery = kbUnitQueryCreate("Gold Resources Query");
		kbUnitQuerySetPlayerID(gGoldQuery, -1, false);
		kbUnitQuerySetPlayerRelation(gGoldQuery, cPlayerRelationAny);
		kbUnitQuerySetIgnoreKnockedOutUnits(gGoldQuery, true);
		kbUnitQuerySetSeeableOnly(gGoldQuery, true);
		kbUnitQuerySetPosition(gGoldQuery, gHomeBase);
		kbUnitQuerySetAreaGroupID(gGoldQuery, kbAreaGroupGetIDByPosition(gHomeBase));
		kbUnitQuerySetAscendingSort(gGoldQuery, true);
	}
	kbUnitQuerySetMaximumDistance(gGoldQuery, 100.0);
	if (kbGetAge() >= cAge4)
		kbUnitQuerySetMaximumDistance(gGoldQuery, 75.0);
	kbUnitQueryResetResults(gGoldQuery);

	// Mountain Monasteries. (Note: Allies of Ethiopia can gather, but it is not enhanced)
	if (totalResourceWorth < gNumGoldVills)
	{
		kbUnitQuerySetPlayerID(gGoldQuery, -1, false);
		kbUnitQuerySetPlayerRelation(gGoldQuery, cPlayerRelationAlly);
		kbUnitQuerySetUnitType(gGoldQuery, cUnitTypedeMountainMonastery);
		kbUnitQuerySetState(gGoldQuery, cUnitStateAlive);
		kbUnitQueryExecute(gGoldQuery);
		numberResults = kbUnitQueryNumberResults(gGoldQuery);

		for (i = 0; < numberResults)
		{
			resourceID = kbUnitQueryGetResult(gGoldQuery, i);

			if (kbUnitGetResourceAmount(resourceID, cResourceGold) < 1.0)
				continue;

			numWorkers = kbUnitGetNumberWorkers(resourceID);
			if (numWorkers >= 20)
			{	// Still count it because we are gathering it.
				resourceWorth = resourceWorth + 1;
				continue;
			}

			if (getDistance(kbUnitGetPosition(resourceID), gHomeBase) > 45)
			{
				if (getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia,
					cUnitStateAlive, kbUnitGetPosition(resourceID), 45.0) > 2)
					continue;
			}

			arrayPushInt(gGoldResources, resourceID);
			arrayPushInt(gGoldNumWorkers, numWorkers);
			arrayPushInt(gMaxGoldWorkers, 20);
			resourceWorth = resourceWorth + 1;
		}

		if (cMyCiv == cCivDEEthiopians)
			resourceWorth = resourceWorth * 18; // Count a Mountain Monastery as 18 Villagers for Ethiopians.
		else
			resourceWorth = resourceWorth * 9; // Count it less since Ethiopia will primarily reap its benefit.
		totalResourceWorth += resourceWorth;
		// Reset for other queries.
		resourceWorth = 0.0;
		kbUnitQueryResetResults(gGoldQuery);
	}

	// Mines.
	//
	// Ethiopians should only check this if we do not have a suitable monastery to work
	// or are almost maxed out working them. Otherwise all civs should check this as the
	// Mountain Monastery poses no benefit to their gathering rates.
	//
	if ((totalResourceWorth < gNumGoldVills) || (cMyCiv != cCivDEEthiopians))
	{
		kbUnitQuerySetPlayerID(gGoldQuery, 0, false);
		kbUnitQuerySetPlayerRelation(gGoldQuery, cPlayerRelationAny);
		kbUnitQuerySetUnitType(gGoldQuery, cUnitTypeAbstractMine);
		kbUnitQuerySetState(gGoldQuery, cUnitStateAlive);
		kbUnitQueryExecute(gGoldQuery);
		numberResults = kbUnitQueryNumberResults(gGoldQuery);

		for (i = 0; < numberResults)
		{
			resourceID = kbUnitQueryGetResult(gGoldQuery, i);
			maxWorkers = 20;

			// AbstractMine also contains building-backed and crate-like
			// prototypes. Only a valid Gaia natural mine belongs here.
			if (getRecoverableNaturalResourceType(
				resourceID, cActionTypeGather) != cResourceGold)
			{
				continue;
			}

			if (resourceCloserToAlly(resourceID))
				continue;

			// We should not consider the mine here as its monastery will have been added
			// from the previous query section.
			if (getUnitCountByLocation(cUnitTypedeMountainMonastery, cPlayerRelationAny,
				cUnitStateABQ, kbUnitGetPosition(resourceID), 5.0) > 0)
				continue;

			// Trading Lodge not in the query since PlayerID is set to 0.
			// Anyways, this works better for building one.
			if (cMyCiv == cCivXPIroquois || cMyCiv == cCivXPSioux)
			{
				tradingLodge = findTradingLodge(resourceID);
				if (tradingLodge < 0)
					continue;
				else
				{
					resourceID = tradingLodge;
					numWorkers = kbUnitGetNumberWorkers(resourceID);
					// Too many current gatherers.
					if (numWorkers >= 10)
					{	// Still count it because we are gathering it.
						resourceWorth = resourceWorth + 1;
						continue;
					}
				}
			}
			else
			{
				numWorkers = getResourceTargetLogicalWorkerCount(
					resourceID, cActionTypeGather, now);
				maxWorkers =
					getRecoveryAdjustedCapacity(resourceID, 20, now);
				// Too many current gatherers.
				if (numWorkers >= maxWorkers)
				{	// Still count it because we are gathering it.
					resourceWorth = resourceWorth + 1;
					continue;
				}
			}

			if (getDistance(kbUnitGetPosition(resourceID), gHomeBase) > 45)
			{
				if (getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia,
					cUnitStateAlive, kbUnitGetPosition(resourceID), 45.0) > 2)
					continue;
			}

			arrayPushInt(gGoldResources, resourceID);
			arrayPushInt(gGoldNumWorkers, numWorkers);
			arrayPushInt(gMaxGoldWorkers, 20);
			resourceWorth = resourceWorth + 1;
		}

		if (cMyCiv == cCivXPIroquois || cMyCiv == cCivXPSioux)
			resourceWorth = resourceWorth * 9; // Count a Tribal Marketplace as 9 villagers.
		else
			resourceWorth = resourceWorth * 18; // Count a Mine as 18 villagers.
		totalResourceWorth += resourceWorth;
		// Reset for other queries.
		resourceWorth = 0.0;
		kbUnitQueryResetResults(gGoldQuery);
	}

	// Estates/Paddies/Fields.
	if (totalResourceWorth < gNumGoldVills || kbGetAge() >= cAge4)
	{
		kbUnitQuerySetMaximumDistance(gGoldQuery, -1);
		kbUnitQuerySetPlayerID(gGoldQuery, cMyID, false);
		kbUnitQuerySetUnitType(gGoldQuery, gPlantationUnit);
		kbUnitQuerySetState(gGoldQuery, cUnitStateAlive);
		kbUnitQueryExecute(gGoldQuery);
		numberResults = kbUnitQueryNumberResults(gGoldQuery);
		int maxNumWorkers = 10;

		for (i = 0; < numberResults)
		{
			resourceID = kbUnitQueryGetResult(gGoldQuery, i);
			numWorkers = kbUnitGetNumberWorkers(resourceID);
			maxNumWorkers = 10;

			// Field on Food or maxed out.
			if (kbUnitIsType(resourceID, cUnitTypedeField))
			{
				if (aiUnitGetTactic(resourceID) == cTacticFieldFood)
					continue;
				else if (numWorkers >= 3)
				{	// Still count it because we are gathering it.
					resourceWorth = resourceWorth + 1;
					continue;
				}
				maxNumWorkers = 3;
			}
			// Paddy on Food or maxed out.
			else if (kbUnitIsType(resourceID, cUnitTypeypRicePaddy))
			{
				if (aiUnitGetTactic(resourceID) == cTacticPaddyFood)
					continue;
				else if (numWorkers >= 10)
				{	// Still count it because we are gathering it.
					resourceWorth = resourceWorth + 1;
					continue;
				}
			}
			// Hacienda on Food or maxed out.
			else if (kbUnitIsType(resourceID, cUnitTypedeHacienda))
			{
				if (aiUnitGetTactic(resourceID) == cTacticHaciendaFood)
					continue;
				else if (numWorkers >= 20)
				{	// Still count it because we are gathering it.
					resourceWorth = resourceWorth + 1;
					continue;
				}
				maxNumWorkers = 20;
			}
			// Estate maxed out.
			else if (numWorkers >= 10)
			{	// Still count it because we are gathering it.
				resourceWorth = resourceWorth + 1;
				continue;
			}

			arrayPushInt(gGoldResources, resourceID);
			arrayPushInt(gGoldNumWorkers, numWorkers);
			arrayPushInt(gMaxGoldWorkers, maxNumWorkers);
			resourceWorth = resourceWorth + 1;
		}

		if (civIsAfrican() == true)
			resourceWorth = resourceWorth * 2.9; // Count a Gold Field as 2.9 villagers.
		else if (cMyCiv == cCivDEMexicans)
			resourceWorth = resourceWorth * 18; // Count a Gold Hacienda as 18 villagers.
		else
			resourceWorth = resourceWorth * 9; // Count an Estate/GoldPaddy as 9 villagers.
		
		totalResourceWorth += resourceWorth;
		// Reset of the query is unecessary as the rule will reset it when it runs again.
	}

	// Basically, if we have reached this point, we should probably build a gold-producing
	// building because we do not want to run out of gold resources.
	int plantationWorth = 10;
	int maxPlans = 4;
	if (cMyCiv == cCivDEMexicans)
	{
		plantationWorth = 20;
		maxPlans = 2;
	}
	else if (civIsAfrican())
	{
		plantationWorth = 3;
		maxPlans = 8;
	}
	if (totalResourceWorth < gNumGoldVills && kbGetAge() >= cAge3)
	{
		arrayRemoveDonePlans(gPlantationTypePlans);
		if (arrayGetSize(gPlantationTypePlans) < maxPlans)
		{
			if (gNumGoldVills - totalResourceWorth > plantationWorth * arrayGetSize(gPlantationTypePlans))
			{
				planID = addPlantationBuildPlan();
				if (planID >= 0)
				{
					arrayPushInt(gPlantationTypePlans, planID);
					aiPlanSetDesiredPriority(planID, 99);
					aiPlanSetDesiredResourcePriority(planID, 99);
				}
			}
		}
	}
}

void updateFoodFishBreakdown(void)
{
	arrayResetSelf(gFoodFishResources);

	int numberResults = 0;
	int resourceID = -1;
	static int foodFishQuery = -1;

	// Search for food.
	if (foodFishQuery < 0)
	{
		foodFishQuery = kbUnitQueryCreate("Food Fish Resources Query");
		kbUnitQuerySetUnitType(foodFishQuery, cUnitTypeAbstractFish);
		kbUnitQuerySetState(foodFishQuery, cUnitStateAlive);
		kbUnitQuerySetPlayerID(foodFishQuery, -1, false);
		kbUnitQuerySetPlayerRelation(foodFishQuery, cPlayerRelationAny);
		kbUnitQuerySetIgnoreKnockedOutUnits(foodFishQuery, true);
		kbUnitQuerySetSeeableOnly(foodFishQuery, true);
	}
	kbUnitQueryResetResults(foodFishQuery);
	numberResults = kbUnitQueryExecute(foodFishQuery);

	for (i = 0; < numberResults)
	{
		resourceID = kbUnitQueryGetResult(foodFishQuery, i);

		// Too many current gatherers.
		xsSetContextPlayer(0);
		if (kbUnitGetNumberWorkers(resourceID) >= 5)
		{
			xsSetContextPlayer(cMyID);
			continue;
		}
		xsSetContextPlayer(cMyID);

		if (getUnitCountByLocation(cUnitTypeLogicalTypeNavalMilitary, cPlayerRelationEnemyNotGaia,
			cUnitStateAlive, kbUnitGetPosition(resourceID), 30.0) > 0)
			continue;

		if (getUnitCountByLocation(cUnitTypeOutpost, cPlayerRelationEnemyNotGaia,
			cUnitStateABQ, kbUnitGetPosition(resourceID), 30.0) > 0)
			continue;

		if (getUnitCountByLocation(cUnitTypeAbstractCallMinutemen, cPlayerRelationEnemyNotGaia,
			cUnitStateABQ, kbUnitGetPosition(resourceID), 30.0) > 0)
			continue;

		if (getUnitCountByLocation(cUnitTypeAbstractDock, cPlayerRelationEnemyNotGaia,
			cUnitStateABQ, kbUnitGetPosition(resourceID), 30.0) > 0)
			continue;

		arrayPushInt(gFoodFishResources, resourceID);
	}
}

void updateGoldFishBreakdown(void)
{
	arrayResetSelf(gGoldFishResources);

	int numberResults = 0;
	int resourceID = -1;
	static int goldFishQuery = -1;

	// Search for gold.
	if (goldFishQuery < 0)
	{
		goldFishQuery = kbUnitQueryCreate("Gold Fish Resources Query");
		kbUnitQuerySetUnitType(goldFishQuery, cUnitTypeAbstractWhale);
		kbUnitQuerySetState(goldFishQuery, cUnitStateAlive);
		kbUnitQuerySetPlayerID(goldFishQuery, -1, false);
		kbUnitQuerySetPlayerRelation(goldFishQuery, cPlayerRelationAny);
		kbUnitQuerySetIgnoreKnockedOutUnits(goldFishQuery, true);
		kbUnitQuerySetSeeableOnly(goldFishQuery, true);
	}
	kbUnitQueryResetResults(goldFishQuery);
	numberResults = kbUnitQueryExecute(goldFishQuery);

	for (i = 0; < numberResults)
	{
		resourceID = kbUnitQueryGetResult(goldFishQuery, i);

		// Too many current gatherers.
		xsSetContextPlayer(0);
		if (kbUnitGetNumberWorkers(resourceID) == 4)
		{
			xsSetContextPlayer(cMyID);
			continue;
		}
		xsSetContextPlayer(cMyID);

		if (getUnitCountByLocation(cUnitTypeLogicalTypeNavalMilitary, cPlayerRelationEnemyNotGaia,
			cUnitStateAlive, kbUnitGetPosition(resourceID), 30.0) > 0)
			continue;

		if (getUnitCountByLocation(cUnitTypeOutpost, cPlayerRelationEnemyNotGaia,
			cUnitStateABQ, kbUnitGetPosition(resourceID), 30.0) > 0)
			continue;

		if (getUnitCountByLocation(cUnitTypeAbstractCallMinutemen, cPlayerRelationEnemyNotGaia,
			cUnitStateABQ, kbUnitGetPosition(resourceID), 30.0) > 0)
			continue;

		if (getUnitCountByLocation(cUnitTypeAbstractDock, cPlayerRelationEnemyNotGaia,
			cUnitStateABQ, kbUnitGetPosition(resourceID), 30.0) > 0)
			continue;

		arrayPushInt(gGoldFishResources, resourceID);
	}
}

//==============================================================================
// The resource IDs, observed worker counts, and per-resource capacities are
// parallel custom arrays. Report alignment failures before tasking can use a
// mismatched index.
//==============================================================================
void checkResourceArrayInvariants()
{
	if (gBetterAIDebug < 1)
		return;
	int foodResourceCount = arrayGetSize(gFoodResources);
	int foodWorkerCount = arrayGetSize(gFoodNumWorkers);
	int foodCapacityCount = arrayGetSize(gMaxFoodWorkers);
	if ((foodResourceCount != foodWorkerCount) || (foodResourceCount != foodCapacityCount))
	{
		debugEvent("ECO-INVARIANT", "food array mismatch resources=" + foodResourceCount +
			", workers=" + foodWorkerCount + ", capacities=" + foodCapacityCount);
	}

	int decayingResourceCount = arrayGetSize(gDecayingAnimals);
	int decayingWorkerCount = arrayGetSize(gDecayingNumWorkers);
	if (decayingResourceCount != decayingWorkerCount)
	{
		debugEvent("ECO-INVARIANT", "decaying array mismatch resources=" + decayingResourceCount +
			", workers=" + decayingWorkerCount);
	}

	int woodResourceCount = arrayGetSize(gWoodResources);
	int woodWorkerCount = arrayGetSize(gWoodNumWorkers);
	if (woodResourceCount != woodWorkerCount)
	{
		debugEvent("ECO-INVARIANT", "wood array mismatch resources=" + woodResourceCount +
			", workers=" + woodWorkerCount);
	}

	int goldResourceCount = arrayGetSize(gGoldResources);
	int goldWorkerCount = arrayGetSize(gGoldNumWorkers);
	int goldCapacityCount = arrayGetSize(gMaxGoldWorkers);
	if ((goldResourceCount != goldWorkerCount) || (goldResourceCount != goldCapacityCount))
	{
		debugEvent("ECO-INVARIANT", "gold array mismatch resources=" + goldResourceCount +
			", workers=" + goldWorkerCount + ", capacities=" + goldCapacityCount);
	}
}

//==============================================================================
// Per-villager natural-resource retry cooldown.
//
// Setting targetID >= 0 records a target to avoid. Passing targetID < 0 reads
// the still-active avoidance target for the unit.
//==============================================================================
int manageGathererRecoveryCooldown(int unitID = -1, int targetID = -1, int now = -1)
{
	const int cGathererRecoveryCapacity = 200;
	const int cGathererRecoveryInterval = 30000;

	static int recoveryUnits = -1;
	static int recoveryTargets = -1;
	static int recoveryTimes = -1;
	static int latestRecoveryTime = -1;

	if (unitID < 0)
		return (-1);
	if (now < 0)
		now = xsGetTime();
	if ((targetID < 0) && ((latestRecoveryTime < 0) ||
		((now - latestRecoveryTime) >= cGathererRecoveryInterval)))
	{
		return (-1);
	}

	if (recoveryUnits < 0)
	{
		recoveryUnits =
			xsArrayCreateInt(cGathererRecoveryCapacity, -1, "Gatherer recovery units");
		recoveryTargets =
			xsArrayCreateInt(cGathererRecoveryCapacity, -1, "Gatherer recovery targets");
		recoveryTimes =
			xsArrayCreateInt(cGathererRecoveryCapacity, -1, "Gatherer recovery times");
	}

	int index = -1;
	int trackedUnitID = -1;
	int trackedTime = -1;
	int elapsed = -1;
	int emptyIndex = -1;
	int oldestIndex = 0;
	int oldestTime = now;
	for (index = 0; < cGathererRecoveryCapacity)
	{
		trackedUnitID = xsArrayGetInt(recoveryUnits, index);
		trackedTime = xsArrayGetInt(recoveryTimes, index);
		if (trackedUnitID == unitID)
		{
			if (targetID >= 0)
			{
				xsArraySetInt(recoveryTargets, index, targetID);
				xsArraySetInt(recoveryTimes, index, now);
				latestRecoveryTime = now;
				return (targetID);
			}

			elapsed = now - trackedTime;
			if ((trackedTime >= 0) && (elapsed < cGathererRecoveryInterval))
				return (xsArrayGetInt(recoveryTargets, index));

			xsArraySetInt(recoveryUnits, index, -1);
			xsArraySetInt(recoveryTargets, index, -1);
			xsArraySetInt(recoveryTimes, index, -1);
			return (-1);
		}
		if ((trackedUnitID < 0) && (emptyIndex < 0))
			emptyIndex = index;
		if (trackedTime < oldestTime)
		{
			oldestTime = trackedTime;
			oldestIndex = index;
		}
	}

	if (targetID < 0)
		return (-1);
	if (emptyIndex < 0)
		emptyIndex = oldestIndex;
	xsArraySetInt(recoveryUnits, emptyIndex, unitID);
	xsArraySetInt(recoveryTargets, emptyIndex, targetID);
	xsArraySetInt(recoveryTimes, emptyIndex, now);
	latestRecoveryTime = now;
	return (targetID);
}

//==============================================================================
// Observe gatherer progress. The watcher returns one eligible natural target
// to avoid when a plan-free gatherer is a clearly separated, stalled outlier
// while closer peers continue depleting the same target. taskVillagers owns
// all retasking.
//==============================================================================
bool shouldReportGathererTargetTransition(int targetID = -1, int reasonID = -1, int now = -1)
{
	const int cGathererTransitionTargetCapacity = 64;
	const int cGathererTransitionTargetInterval = 5000;

	static int transitionTargets = -1;
	static int transitionReasons = -1;
	static int transitionTimes = -1;

	if ((targetID < 0) || (reasonID < 0))
		return(true);

	if (transitionTargets < 0)
	{
		transitionTargets =
			xsArrayCreateInt(cGathererTransitionTargetCapacity, -1, "Gather transition targets");
		transitionReasons =
			xsArrayCreateInt(cGathererTransitionTargetCapacity, -1, "Gather transition reasons");
		transitionTimes =
			xsArrayCreateInt(cGathererTransitionTargetCapacity, -1, "Gather transition times");
	}

	int emptyIndex = -1;
	int oldestIndex = 0;
	int oldestTime = now;
	int index = -1;
	int trackedTarget = -1;
	int trackedReason = -1;
	int trackedTime = -1;
	for (index = 0; < cGathererTransitionTargetCapacity)
	{
		trackedTarget = xsArrayGetInt(transitionTargets, index);
		trackedReason = xsArrayGetInt(transitionReasons, index);
		trackedTime = xsArrayGetInt(transitionTimes, index);

		if ((trackedTarget == targetID) && (trackedReason == reasonID))
		{
			if ((trackedTime >= 0) && ((now - trackedTime) < cGathererTransitionTargetInterval))
				return(false);

			xsArraySetInt(transitionTimes, index, now);
			return(true);
		}

		if ((trackedTarget < 0) && (emptyIndex < 0))
			emptyIndex = index;
		if (trackedTime < oldestTime)
		{
			oldestTime = trackedTime;
			oldestIndex = index;
		}
	}

	if (emptyIndex < 0)
		emptyIndex = oldestIndex;
	xsArraySetInt(transitionTargets, emptyIndex, targetID);
	xsArraySetInt(transitionReasons, emptyIndex, reasonID);
	xsArraySetInt(transitionTimes, emptyIndex, now);
	return(true);
}

int getGatherTelemetryResourceType(int targetID = -1, int actionID = -1)
{
	if (targetID < 0)
	{
		return(-1);
	}

	if (actionID == cActionTypeHunting)
	{
		if (kbUnitIsType(targetID, cUnitTypeTree))
		{
			return(cResourceWood);
		}
		if (kbUnitIsType(targetID, cUnitTypeHuntable) ||
			kbUnitIsType(targetID, cUnitTypeHerdable))
		{
			return(cResourceFood);
		}
		return(-1);
	}

	if (actionID != cActionTypeGather)
	{
		return(-1);
	}
	if (kbUnitIsType(targetID, cUnitTypedeHacienda))
	{
		if (aiUnitGetTactic(targetID) == cTacticHaciendaCoin)
		{
			return(cResourceGold);
		}
		return(cResourceFood);
	}
	if (kbUnitIsType(targetID, cUnitTypeypRicePaddy) ||
		kbUnitIsType(targetID, cUnitTypedeField))
	{
		if (aiUnitGetTactic(targetID) == gFarmGoldTactic)
		{
			return(cResourceGold);
		}
		return(cResourceFood);
	}
	if (kbUnitIsType(targetID, cUnitTypeGold))
	{
		return(cResourceGold);
	}
	if (kbUnitIsType(targetID, cUnitTypeFood))
	{
		return(cResourceFood);
	}
	if (kbUnitIsType(targetID, cUnitTypeWood))
	{
		return(cResourceWood);
	}

	float foodAmount = kbUnitGetResourceAmount(targetID, cResourceFood);
	float woodAmount = kbUnitGetResourceAmount(targetID, cResourceWood);
	float goldAmount = kbUnitGetResourceAmount(targetID, cResourceGold);
	if ((foodAmount > 0.0) && (foodAmount >= woodAmount) && (foodAmount >= goldAmount))
	{
		return(cResourceFood);
	}
	if ((woodAmount > 0.0) && (woodAmount >= goldAmount))
	{
		return(cResourceWood);
	}
	if (goldAmount > 0.0)
	{
		return(cResourceGold);
	}
	return(-1);
}


int watchGathererTelemetry(int unitID = -1, int actionID = -1)
{
	const int cGathererWatchCapacity = 200;
	const int cGathererWatchWindow = 4000;
	const int cGathererWatchSuspectInterval = 30000;
	const int cGathererWatchTransitionInterval = 5000;
	const int cGathererWatchStaleInterval = 5000;

	static int watchUnits = -1;
	static int watchActions = -1;
	static int watchTargets = -1;
	static int watchRawTargets = -1;
	static int watchResourceTypes = -1;
	static int watchPositions = -1;
	static int watchTargetPositions = -1;
	static int watchCarriedFood = -1;
	static int watchTargetFood = -1;
	static int watchElapsedTimes = -1;
	static int watchTargetStartTimes = -1;
	static int watchWindowStartTimes = -1;
	static int watchWindowStartPositions = -1;
	static int watchWindowStartDistances = -1;
	static int watchWindowBestDistances = -1;
	static int watchWindowStartCarriedFood = -1;
	static int watchWindowStartTargetFood = -1;
	static int watchStalledWindows = -1;
	static int watchLastSuspectTimes = -1;
	static int watchLastTransitionTimes = -1;
	static int watchLastSeenTimes = -1;

	bool telemetryEnabled = (gBetterAIDebug >= 1) || (cDebugEconomy == true);
	if (unitID < 0)
		return (-1);
	// Only current direct-task gatherers enter the target lookup and watch scan.
	if ((actionID != cActionTypeHunting) && (actionID != cActionTypeGather))
		return (-1);
	// With telemetry disabled, only the explicit natural-resource whitelist
	// enters the behavioral watcher. Debug mode may still observe other direct
	// Gather targets without granting them behavioral recovery.
	if (telemetryEnabled == false)
	{
		if (getRecoverableNaturalResourceType(
			kbUnitGetTargetUnitID(unitID), actionID) < 0)
		{
			// Invalidate any prior recovery sample just as full telemetry would
			// when observing a switch away from a recoverable natural target.
			if (watchUnits >= 0)
			{
				int resetWatchIndex = -1;
				for (resetWatchIndex = 0; < cGathererWatchCapacity)
				{
					if (xsArrayGetInt(watchUnits, resetWatchIndex) == unitID)
					{
						xsArraySetInt(watchUnits, resetWatchIndex, -1);
						xsArraySetInt(watchLastSeenTimes, resetWatchIndex, -1);
						break;
					}
				}
			}
			return (-1);
		}
	}

	if (watchUnits < 0)
	{
		watchUnits = xsArrayCreateInt(cGathererWatchCapacity, -1, "Gather watch units");
		watchActions = xsArrayCreateInt(cGathererWatchCapacity, -1, "Gather watch actions");
		watchTargets = xsArrayCreateInt(cGathererWatchCapacity, -1, "Gather watch targets");
		watchRawTargets = xsArrayCreateInt(cGathererWatchCapacity, -1, "Gather watch raw targets");
		watchResourceTypes = xsArrayCreateInt(cGathererWatchCapacity, -1, "Gather watch resource types");
		watchPositions = xsArrayCreateVector(cGathererWatchCapacity, cInvalidVector, "Gather watch positions");
		watchTargetPositions =
			xsArrayCreateVector(cGathererWatchCapacity, cInvalidVector, "Gather watch target positions");
		watchCarriedFood = xsArrayCreateFloat(cGathererWatchCapacity, -1.0, "Gather watch carried resource");
		watchTargetFood = xsArrayCreateFloat(cGathererWatchCapacity, -1.0, "Gather watch target resource");
		watchElapsedTimes = xsArrayCreateInt(cGathererWatchCapacity, -1, "Gather watch elapsed times");
		watchTargetStartTimes = xsArrayCreateInt(cGathererWatchCapacity, -1, "Gather watch target start times");
		watchWindowStartTimes = xsArrayCreateInt(cGathererWatchCapacity, -1, "Gather watch window start times");
		watchWindowStartPositions =
			xsArrayCreateVector(cGathererWatchCapacity, cInvalidVector, "Gather watch window start positions");
		watchWindowStartDistances =
			xsArrayCreateFloat(cGathererWatchCapacity, -1.0, "Gather watch window start distances");
		watchWindowBestDistances =
			xsArrayCreateFloat(cGathererWatchCapacity, -1.0, "Gather watch window best distances");
		watchWindowStartCarriedFood =
			xsArrayCreateFloat(cGathererWatchCapacity, -1.0, "Gather watch window start carried resource");
		watchWindowStartTargetFood =
			xsArrayCreateFloat(cGathererWatchCapacity, -1.0, "Gather watch window start target resource");
		watchStalledWindows = xsArrayCreateInt(cGathererWatchCapacity, 0, "Gather watch stalled windows");
		watchLastSuspectTimes = xsArrayCreateInt(cGathererWatchCapacity, -1, "Gather watch last suspect times");
		watchLastTransitionTimes =
			xsArrayCreateInt(cGathererWatchCapacity, -1, "Gather watch last transition times");
		watchLastSeenTimes = xsArrayCreateInt(cGathererWatchCapacity, -1, "Gather watch last seen times");
	}

	int now = xsGetTime();
	bool verboseTelemetry =
		(telemetryEnabled == true) &&
		((cDebugEconomy == true) || (gBetterAIDebug >= 2));
	int rawTargetID = kbUnitGetTargetUnitID(unitID);
	int resourceType = getGatherTelemetryResourceType(rawTargetID, actionID);
	bool rawTargetIsGatherable = false;
	bool targetHasFiniteResource = false;
	vector targetPosition = cInvalidVector;
	float targetFood = -1.0;
	if ((rawTargetID >= 0) && (resourceType >= 0))
	{
		rawTargetIsGatherable = true;
		targetHasFiniteResource = (kbUnitIsType(rawTargetID, cUnitTypeBuilding) == false);
		targetPosition = kbUnitGetPosition(rawTargetID);
		targetFood = kbUnitGetResourceAmount(rawTargetID, resourceType);
	}

	int gatheringTargetID = -1;
	if ((rawTargetID >= 0) && rawTargetIsGatherable &&
		(targetPosition != cInvalidVector) &&
		((targetHasFiniteResource == false) || (targetFood > 0.0)))
	{
		gatheringTargetID = rawTargetID;
	}

	vector currentPosition = kbUnitGetPosition(unitID);
	float carriedFood = -1.0;
	if (resourceType >= 0)
	{
		carriedFood = kbUnitGetResourceAmount(unitID, resourceType);
	}
	float targetDistance = -1.0;
	if (targetPosition != cInvalidVector)
		targetDistance = getDistance(currentPosition, targetPosition);

	int watchIndex = -1;
	int emptyIndex = -1;
	int oldestIndex = 0;
	int oldestTime = now;
	int trackedUnitID = -1;
	int lastSeenTime = -1;
	int index = -1;
	for (index = 0; < cGathererWatchCapacity)
	{
		trackedUnitID = xsArrayGetInt(watchUnits, index);
		if (trackedUnitID == unitID)
		{
			watchIndex = index;
			break;
		}
		if ((trackedUnitID < 0) && (emptyIndex < 0))
			emptyIndex = index;

		lastSeenTime = xsArrayGetInt(watchLastSeenTimes, index);
		if (lastSeenTime < oldestTime)
		{
			oldestTime = lastSeenTime;
			oldestIndex = index;
		}
	}

	if (watchIndex < 0)
	{
		watchIndex = emptyIndex;
		if (watchIndex < 0)
			watchIndex = oldestIndex;

		xsArraySetInt(watchUnits, watchIndex, unitID);
		xsArraySetInt(watchActions, watchIndex, -1);
		xsArraySetInt(watchTargets, watchIndex, -1);
		xsArraySetInt(watchRawTargets, watchIndex, -1);
		xsArraySetInt(watchResourceTypes, watchIndex, -1);
		xsArraySetVector(watchPositions, watchIndex, cInvalidVector);
		xsArraySetVector(watchTargetPositions, watchIndex, cInvalidVector);
		xsArraySetFloat(watchCarriedFood, watchIndex, -1.0);
		xsArraySetFloat(watchTargetFood, watchIndex, -1.0);
		xsArraySetInt(watchElapsedTimes, watchIndex, -1);
		xsArraySetInt(watchTargetStartTimes, watchIndex, -1);
		xsArraySetInt(watchWindowStartTimes, watchIndex, -1);
		xsArraySetVector(watchWindowStartPositions, watchIndex, cInvalidVector);
		xsArraySetFloat(watchWindowStartDistances, watchIndex, -1.0);
		xsArraySetFloat(watchWindowBestDistances, watchIndex, -1.0);
		xsArraySetFloat(watchWindowStartCarriedFood, watchIndex, -1.0);
		xsArraySetFloat(watchWindowStartTargetFood, watchIndex, -1.0);
		xsArraySetInt(watchStalledWindows, watchIndex, 0);
		xsArraySetInt(watchLastSuspectTimes, watchIndex, -1);
		xsArraySetInt(watchLastTransitionTimes, watchIndex, -1);
	}
	else
	{
		lastSeenTime = xsArrayGetInt(watchLastSeenTimes, watchIndex);
		if ((lastSeenTime >= 0) && ((now - lastSeenTime) > cGathererWatchStaleInterval))
		{
			xsArraySetInt(watchActions, watchIndex, -1);
			xsArraySetInt(watchTargets, watchIndex, -1);
			xsArraySetInt(watchRawTargets, watchIndex, -1);
			xsArraySetInt(watchResourceTypes, watchIndex, -1);
			xsArraySetVector(watchPositions, watchIndex, cInvalidVector);
			xsArraySetVector(watchTargetPositions, watchIndex, cInvalidVector);
			xsArraySetFloat(watchCarriedFood, watchIndex, -1.0);
			xsArraySetFloat(watchTargetFood, watchIndex, -1.0);
			xsArraySetInt(watchElapsedTimes, watchIndex, -1);
			xsArraySetInt(watchTargetStartTimes, watchIndex, -1);
			xsArraySetInt(watchWindowStartTimes, watchIndex, -1);
			xsArraySetVector(watchWindowStartPositions, watchIndex, cInvalidVector);
			xsArraySetFloat(watchWindowStartDistances, watchIndex, -1.0);
			xsArraySetFloat(watchWindowBestDistances, watchIndex, -1.0);
			xsArraySetFloat(watchWindowStartCarriedFood, watchIndex, -1.0);
			xsArraySetFloat(watchWindowStartTargetFood, watchIndex, -1.0);
			xsArraySetInt(watchStalledWindows, watchIndex, 0);
			xsArraySetInt(watchLastSuspectTimes, watchIndex, -1);
			xsArraySetInt(watchLastTransitionTimes, watchIndex, -1);
		}
	}
	xsArraySetInt(watchLastSeenTimes, watchIndex, now);

	int previousAction = xsArrayGetInt(watchActions, watchIndex);
	int previousTarget = xsArrayGetInt(watchTargets, watchIndex);
	int previousRawTarget = xsArrayGetInt(watchRawTargets, watchIndex);
	int previousResourceType = xsArrayGetInt(watchResourceTypes, watchIndex);
	float previousTargetFood = xsArrayGetFloat(watchTargetFood, watchIndex);
	int previousTargetStartTime = xsArrayGetInt(watchTargetStartTimes, watchIndex);
	int previousElapsed = 0;
	if (previousTargetStartTime >= 0)
		previousElapsed = now - previousTargetStartTime;

	bool targetTransition = false;
	int transitionReasonID = -1;
	string transitionReason = "";
	if (((previousAction == cActionTypeHunting) || (previousAction == cActionTypeGather)) &&
		(previousTarget >= 0))
	{
		if (rawTargetID < 0)
		{
			targetTransition = true;
			transitionReasonID = 0;
			transitionReason = "raw-lost";
		}
		else if (rawTargetID != previousTarget)
		{
			targetTransition = true;
			transitionReasonID = 1;
			transitionReason = "target-changed";
		}
		else if ((rawTargetIsGatherable == false) || (resourceType != previousResourceType))
		{
			targetTransition = true;
			transitionReasonID = 2;
			transitionReason = "type-lost";
		}
		else if (targetPosition == cInvalidVector)
		{
			targetTransition = true;
			transitionReasonID = 3;
			transitionReason = "position-invalid";
		}
		else if ((targetHasFiniteResource == true) && (targetFood <= 0.0))
		{
			targetTransition = true;
			transitionReasonID = 4;
			transitionReason = "resource-empty";
		}
	}

	if (targetTransition == true)
	{
		float previousTargetCurrentFood = -1.0;
		vector previousTargetCurrentPosition = cInvalidVector;
		bool previousTargetStillGatherable = false;
		if (previousTarget == rawTargetID)
		{
			previousTargetCurrentFood = targetFood;
			previousTargetCurrentPosition = targetPosition;
			previousTargetStillGatherable = rawTargetIsGatherable;
		}
		else if ((verboseTelemetry == true) && (previousTarget >= 0) &&
			(previousResourceType >= 0))
		{
			previousTargetCurrentFood =
				kbUnitGetResourceAmount(previousTarget, previousResourceType);
			previousTargetCurrentPosition = kbUnitGetPosition(previousTarget);
			previousTargetStillGatherable =
				(getGatherTelemetryResourceType(previousTarget, previousAction) >= 0);
		}

		int lastTransitionTime = xsArrayGetInt(watchLastTransitionTimes, watchIndex);
		int timeSinceLastTransition = now - lastTransitionTime;
		if ((telemetryEnabled == true) &&
			((lastTransitionTime < 0) ||
			(timeSinceLastTransition >= cGathererWatchTransitionInterval)))
		{
			if (shouldReportGathererTargetTransition(previousTarget, transitionReasonID, now) == true)
			{
				// Keep curated output far below the engine's observed 511-byte
				// formatted-line crash boundary. Detailed vectors are separate
				// level-2 lines with bounded field sets.
				debugEvent("ECO-WATCH", "transition u=" + unitID + " reason=" + transitionReason +
					" action=" + previousAction + ">" + actionID +
					" target=" + previousTarget + ">" + rawTargetID +
					" res=" + previousResourceType + ">" + resourceType +
					" amount=" + previousTargetFood + ">" + previousTargetCurrentFood +
					" ms=" + previousElapsed);
				if (verboseTelemetry == true)
				{
					debugEconomy("ECO-WATCH transition-detail u=" + unitID +
						" prevRaw=" + previousRawTarget + " raw=" + rawTargetID +
						" gatherable=" + (previousTargetStillGatherable ? "true" : "false") +
						" carried=" + carriedFood + " distance=" + targetDistance);
					debugEconomy("ECO-WATCH transition-pos u=" + unitID +
						" villager=" + currentPosition + " rawTarget=" + targetPosition);
					debugEconomy("ECO-WATCH transition-prev-pos u=" + unitID +
						" previousTarget=" + previousTargetCurrentPosition);
				}
			}
			xsArraySetInt(watchLastTransitionTimes, watchIndex, now);
		}

		// A depleted or invalid same target is no longer a usable telemetry target.
		if ((rawTargetID == previousTarget) &&
			((rawTargetIsGatherable == false) || (targetPosition == cInvalidVector) ||
			((targetHasFiniteResource == true) && (targetFood <= 0.0))))
		{
			gatheringTargetID = -1;
		}
	}

	if ((gatheringTargetID < 0) || (previousAction != actionID) ||
		(previousTarget != gatheringTargetID) || (previousResourceType != resourceType))
	{
		xsArraySetInt(watchTargetStartTimes, watchIndex, now);
		xsArraySetInt(watchWindowStartTimes, watchIndex, now);
		xsArraySetVector(watchWindowStartPositions, watchIndex, currentPosition);
		xsArraySetFloat(watchWindowStartDistances, watchIndex, targetDistance);
		xsArraySetFloat(watchWindowBestDistances, watchIndex, targetDistance);
		xsArraySetFloat(watchWindowStartCarriedFood, watchIndex, carriedFood);
		xsArraySetFloat(watchWindowStartTargetFood, watchIndex, targetFood);
		xsArraySetInt(watchStalledWindows, watchIndex, 0);
		xsArraySetInt(watchLastSuspectTimes, watchIndex, -1);
	}
	else
	{
		float bestDistance = xsArrayGetFloat(watchWindowBestDistances, watchIndex);
		if ((targetDistance >= 0.0) &&
			((bestDistance < 0.0) || (targetDistance < bestDistance)))
		{
			xsArraySetFloat(watchWindowBestDistances, watchIndex, targetDistance);
		}
	}

	xsArraySetInt(watchActions, watchIndex, actionID);
	xsArraySetInt(watchTargets, watchIndex, gatheringTargetID);
	xsArraySetInt(watchRawTargets, watchIndex, rawTargetID);
	xsArraySetInt(watchResourceTypes, watchIndex, resourceType);
	xsArraySetVector(watchPositions, watchIndex, currentPosition);
	xsArraySetVector(watchTargetPositions, watchIndex, targetPosition);
	xsArraySetFloat(watchCarriedFood, watchIndex, carriedFood);
	xsArraySetFloat(watchTargetFood, watchIndex, targetFood);

	int elapsed = 0;
	if (gatheringTargetID >= 0)
		elapsed = now - xsArrayGetInt(watchTargetStartTimes, watchIndex);
	xsArraySetInt(watchElapsedTimes, watchIndex, elapsed);

	if (gatheringTargetID < 0)
		return (-1);

	int windowElapsed = now - xsArrayGetInt(watchWindowStartTimes, watchIndex);
	if (verboseTelemetry == true)
	{
		debugEconomy("ECO-WATCH sample u=" + unitID + " action=" + actionID +
			" res=" + resourceType + " target=" + gatheringTargetID + " raw=" +
			rawTargetID + " distance=" + targetDistance + " carried=" + carriedFood +
			" amount=" + targetFood + " ms=" + elapsed);
		debugEconomy("ECO-WATCH sample-pos u=" + unitID +
			" villager=" + currentPosition + " target=" + targetPosition);
	}

	if (windowElapsed < cGathererWatchWindow)
		return (-1);

	float movement = getDistance(currentPosition, xsArrayGetVector(watchWindowStartPositions, watchIndex));
	float carriedFoodProgress = carriedFood - xsArrayGetFloat(watchWindowStartCarriedFood, watchIndex);
	float targetFoodProgress = xsArrayGetFloat(watchWindowStartTargetFood, watchIndex) - targetFood;
	float startDistance = xsArrayGetFloat(watchWindowStartDistances, watchIndex);
	float bestWindowDistance = xsArrayGetFloat(watchWindowBestDistances, watchIndex);
	float approachProgress = -1.0;
	if ((startDistance >= 0.0) && (bestWindowDistance >= 0.0))
	{
		approachProgress = startDistance - bestWindowDistance;
	}
	bool individualNoProgress =
		(movement <= 0.25) &&
		(approachProgress <= 0.25) &&
		(carriedFoodProgress <= 0.01);
	int stalledWindowCount = xsArrayGetInt(watchStalledWindows, watchIndex);
	if (individualNoProgress == true)
	{
		stalledWindowCount++;
	}
	else
	{
		stalledWindowCount = 0;
	}
	xsArraySetInt(watchStalledWindows, watchIndex, stalledWindowCount);

	if (verboseTelemetry == true)
	{
		debugEconomy("ECO-WATCH window u=" + unitID + " move=" + movement +
			" approach=" + approachProgress + " carriedDelta=" + carriedFoodProgress +
			" sharedDelta=" + targetFoodProgress + " stalled=" + stalledWindowCount);
	}

	int recoveryTargetID = -1;
	if (stalledWindowCount >= 2)
	{
		int eligibleResourceType =
			getRecoverableNaturalResourceType(gatheringTargetID, actionID);
		int targetKind =
			getRecoverableNaturalTargetKind(gatheringTargetID, actionID);
		float workDistance =
			getRecoverableNaturalTargetWorkDistance(gatheringTargetID, actionID);
		int peerResultCount = kbUnitQueryNumberResults(gVillagerQuery);
		int peerIndex = 0;
		int peerUnitID = -1;
		int closerPeerCount = 0;
		float peerDistance = -1.0;
		float closestPeerDistance = 9999.0;
		vector peerPosition = cInvalidVector;
		for (peerIndex = 0; < peerResultCount)
		{
			peerUnitID = kbUnitQueryGetResult(gVillagerQuery, peerIndex);
			if ((peerUnitID == unitID) ||
				(kbUnitGetActionType(peerUnitID) != actionID) ||
				(kbUnitGetTargetUnitID(peerUnitID) != gatheringTargetID))
			{
				continue;
			}
			peerPosition = kbUnitGetPosition(peerUnitID);
			if (peerPosition == cInvalidVector)
			{
				continue;
			}
			peerDistance = getDistance(peerPosition, targetPosition);
			if (peerDistance < closestPeerDistance)
			{
				closestPeerDistance = peerDistance;
			}
			if (peerDistance < targetDistance)
			{
				closerPeerCount++;
			}
		}

		bool hasPeer = (closestPeerDistance < 9999.0);
		bool offsetFromPeer =
			(hasPeer == true) && (targetDistance > (closestPeerDistance + 1.5));
		bool groupNoProgress =
			(targetHasFiniteResource == true) &&
			(targetFoodProgress <= 0.01) &&
			(targetDistance > workDistance);
		bool reportCandidate = offsetFromPeer || groupNoProgress;

		// The carried-resource syscall has been uninformative for some gatherers,
		// so behavioral recovery requires a much stronger outlier pattern than
		// the observational candidate: a plan-free gatherer remains away from an
		// eligible natural target while a closer same-action peer depletes it.
		bool recoverBlockedGatherer =
			(eligibleResourceType == resourceType) &&
			(targetHasFiniteResource == true) &&
			(individualNoProgress == true) &&
			(targetFoodProgress > 0.01) &&
			(closerPeerCount > 0) &&
			(closestPeerDistance <= workDistance) &&
			(offsetFromPeer == true) &&
			(targetDistance > workDistance) &&
			(kbUnitGetPlanID(unitID) < 0);
		if (recoverBlockedGatherer == true)
		{
			int activeRecoveryTargetID =
				manageGathererRecoveryCooldown(unitID, -1, now);
			if (activeRecoveryTargetID < 0)
			{
				recoveryTargetID =
					manageGathererRecoveryCooldown(unitID, gatheringTargetID, now);
				int pressureActive =
					manageGathererRecoveryPressure(gatheringTargetID, true, now);
				if (telemetryEnabled == true)
				{
					int recoveryCapacity =
						getRecoverableNaturalTargetWorkerCapacity(
							gatheringTargetID, now);
					int engineWorkers =
						getResourceTargetEngineWorkerCount(gatheringTargetID);
					int rawWorkers =
						countVillagersTargetingResource(
							gatheringTargetID, actionID);
					int targetLiveState = -1;
					if (targetKind == 0)
						targetLiveState =
							(kbUnitGetCurrentHitpoints(gatheringTargetID) > 0.0 ? 1 : 0);
					debugEvent("ECO-RECOVER", "u=" + unitID + " t=" + gatheringTargetID +
						" kind=" + targetKind + " res=" + resourceType +
						" live=" + targetLiveState + " remain=" + targetFood +
						" dist=" + targetDistance + " shared=" + targetFoodProgress +
						" peers=" + closerPeerCount + " closest=" + closestPeerDistance +
						" engine=" + engineWorkers + " raw=" + rawWorkers +
						" cap=" + recoveryCapacity + " pressure=" + pressureActive +
						" windows=" + stalledWindowCount + " cooldown=30000");
				}
			}
		}

		if ((telemetryEnabled == true) && (reportCandidate == true))
		{
			int lastSuspectTime = xsArrayGetInt(watchLastSuspectTimes, watchIndex);
			int timeSinceLastSuspect = now - lastSuspectTime;
			if ((lastSuspectTime < 0) ||
				(timeSinceLastSuspect >= cGathererWatchSuspectInterval))
			{
				debugEvent("ECO-WATCH", "candidate u=" + unitID + " action=" + actionID +
					" res=" + resourceType + " target=" + gatheringTargetID + " dist=" +
					targetDistance + " move=" + movement + " approach=" + approachProgress +
					" shared=" + targetFoodProgress + " windows=" + stalledWindowCount +
					" peers=" + closerPeerCount + " closest=" + closestPeerDistance);
				if (verboseTelemetry == true)
				{
					debugEconomy("ECO-WATCH candidate-detail u=" + unitID + " plan=" +
						kbUnitGetPlanID(unitID) + " carried=" + carriedFood + " carriedDelta=" +
						carriedFoodProgress + " workers=" +
						getResourceTargetEngineWorkerCount(gatheringTargetID));
					debugEconomy("ECO-WATCH candidate-pos u=" + unitID +
						" villager=" + currentPosition + " target=" + targetPosition);
				}
				xsArraySetInt(watchLastSuspectTimes, watchIndex, now);
			}
		}
	}

	// Begin another independent movement/progress observation window on the same target.
	xsArraySetInt(watchWindowStartTimes, watchIndex, now);
	xsArraySetVector(watchWindowStartPositions, watchIndex, currentPosition);
	xsArraySetFloat(watchWindowStartDistances, watchIndex, targetDistance);
	xsArraySetFloat(watchWindowBestDistances, watchIndex, targetDistance);
	xsArraySetFloat(watchWindowStartCarriedFood, watchIndex, carriedFood);
	xsArraySetFloat(watchWindowStartTargetFood, watchIndex, targetFood);
	return (recoveryTargetID);
}

//==============================================================================
//
// taskVillagers
//
// - Control villager gathering assignments.
//
//==============================================================================
rule taskVillagers
inactive
minInterval 1 // Experimental responsiveness trial; recovery windows remain elapsed-time based.
{
	if (gVillagerQuery < 0)
	{
		gVillagerQuery = kbUnitQueryCreate("Villager Query");
		kbUnitQuerySetPlayerID(gVillagerQuery, cMyID);
		kbUnitQuerySetPlayerRelation(gVillagerQuery, -1);
		kbUnitQuerySetState(gVillagerQuery, cUnitStateAlive);
		kbUnitQuerySetPosition(gVillagerQuery, gHomeBase);
		kbUnitQuerySetAscendingSort(gVillagerQuery, true);
		kbUnitQuerySetIgnoreKnockedOutUnits(gVillagerQuery, true);
	}
	kbUnitQueryResetResults(gVillagerQuery);
	kbUnitQuerySetUnitType(gVillagerQuery, cUnitTypeLogicalTypeSettlerBuildLimit);
	kbUnitQueryExecute(gVillagerQuery);
	kbUnitQuerySetUnitType(gVillagerQuery, cUnitTypeSettlerWagon);
	kbUnitQueryExecute(gVillagerQuery);

	if (xsIsRuleEnabled("villagerRetreat") == false)
	{
		xsEnableRule("villagerRetreat");
	}

	// Used throughout the rule to manage the villagers.
	int villagerPop = kbGetPopulationSlotsByQueryID(gVillagerQuery) +
		getDedicatedGatherers(cResourceFood) +
		getDedicatedGatherers(cResourceWood) +
		getDedicatedGatherers(cResourceGold);
	int numFoodVills = 0;
	int numWoodVills = 0;
	int numGoldVills = 0;
	int pop = 1;
	int unitID = -1;
	int actionID = -1;
	int resourceID = -1;
	int planID = -1;
	int recoveryAvoidTargetID = -1;
	int telemetryRecoveryTargetID = -1;
	bool forceGathererRecovery = false;
	int currentNaturalActionID = -1;
	int currentNaturalResourceType = -1;
	bool bypassCurrentNaturalTarget = false;
	int candidateActionID = -1;
	int candidateResourceType = -1;
	int candidateCapacity = -1;
	int candidateWorkerCount = -1;
	bool candidateInvalid = false;
	int selectionNow = -1;
	int decayingCapacity = -1;
	int decayingMaximumCapacity = 5;
	int assignmentCapacity = -1;
	int reservationResult = -1;
	bool assignedAnimalTarget = false;
	bool assignedLiveTarget = false;

	// Used to compare resources within each resource type, to select the
	// "best" one relative to the villager under consideration.
	vector location = cInvalidVector;
	int tempIndex = -1;
	int closestResourceID = -1;
	int closestResourceIndex = -1;
	float closestDistance = 0.0;
	float tempDistance = 0.0;

	// Used to keep track of the "best" resource of each type, in the sense
	// of their relative location to the current villager being considered.
	// The villager is then tasked to the closest one of these resources.
	int foodID = -1;
	int foodIndex = -1;
	float foodDistance = 0.0;
	bool foodFromDecayingArray = false;
	int woodID = -1;
	int woodIndex = -1;
	float woodDistance = 0.0;
	int goldID = -1;
	int goldIndex = -1;
	float goldDistance = 0.0;

	// Used to task a villager to shoot hunts toward a particular location.
	vector targetLocation = cInvalidVector;

	// Subtract from our total count villagers that are assigned to a plan,
	// as well as those on crates. Also, make sure crates are gathered.
	for (i = 0; < kbUnitQueryNumberResults(gVillagerQuery))
	{
		unitID = kbUnitQueryGetResult(gVillagerQuery, i);
		if (kbUnitIsType(unitID, cUnitTypeSettlerWagon))
			pop = 2;
		else
			pop = 1;

		if (kbUnitGetPlanID(unitID) >= 0)
			villagerPop = villagerPop - pop;
	}
	/* villagerPop = villagerPop - gReservedFoodVillagers -
		gReservedWoodVillagers - gReservedGoldVillagers;
	if (villagerPop < 0)
		villagerPop = 0; */

	numFoodVills = (villagerPop - gReservedFoodVillagers - gReservedWoodVillagers - gReservedGoldVillagers) * 
					aiGetResourcePercentage(cResourceFood) + gReservedFoodVillagers;
	numGoldVills = (villagerPop - gReservedFoodVillagers - gReservedWoodVillagers - gReservedGoldVillagers) *
					aiGetResourcePercentage(cResourceGold) + gReservedGoldVillagers;
	// villagerPop = villagerPop + gReservedFoodVillagers + gReservedGoldVillagers;
	numWoodVills = (villagerPop - gReservedFoodVillagers - gReservedWoodVillagers - gReservedGoldVillagers) *
					aiGetResourcePercentage(cResourceWood) + gReservedWoodVillagers;

	numFoodVills = numFoodVills - getDedicatedGatherers(cResourceFood);
	if (numFoodVills < 0)
		numFoodVills = 0;
	numGoldVills = numGoldVills - getDedicatedGatherers(cResourceGold);
	if (numGoldVills < 0)
		numGoldVills = 0;
	numWoodVills = numWoodVills - getDedicatedGatherers(cResourceWood);
	if (numWoodVills < 0)
		numWoodVills = 0;

	// Set the global gatherer data.
	gNumFoodVills = numFoodVills;
	gNumWoodVills = numWoodVills;
	gNumGoldVills = numGoldVills;

	// Search for food.
	updateFoodBreakdown();

	// Search for wood.
	updateWoodBreakdown();

	// Search for gold.
	updateGoldBreakdown();
	checkResourceArrayInvariants();

	if (arrayGetSize(gWoodResources) < 2) // Until I configure arrayGetSize to return 0.
	{
		numFoodVills = numFoodVills + (numWoodVills / 2);
		numGoldVills = numGoldVills + (numWoodVills / 2) + (numWoodVills % 2);
		numWoodVills = 0;
	}

	// ============================================================ //

	// Loop through the villagers (from the query) to give them assignments.
	for (i = 0; < kbUnitQueryNumberResults(gVillagerQuery))
	{
		unitID = kbUnitQueryGetResult(gVillagerQuery, i);
		actionID = kbUnitGetActionType(unitID);
		recoveryAvoidTargetID = -1;
		telemetryRecoveryTargetID = -1;
		forceGathererRecovery = false;
		if ((actionID == cActionTypeHunting) || (actionID == cActionTypeGather))
		{
			telemetryRecoveryTargetID = watchGathererTelemetry(unitID, actionID);
			if (telemetryRecoveryTargetID >= 0)
				recoveryAvoidTargetID = telemetryRecoveryTargetID;
		}
		if (recoveryAvoidTargetID < 0)
			recoveryAvoidTargetID =
				manageGathererRecoveryCooldown(unitID, -1, xsGetTime());
		targetLocation = cInvalidVector;
		switch (actionID)
		{
			case cActionTypeMove: // Currently moving.
			case cActionTypeMoveByGroup: // Currently moving.
			case cActionTypeSocialise: // Currently on Community Plaza.
				continue;
			case cActionTypeBuild: // Currently building in a plan.
			{
				if (kbUnitGetPlanID(unitID) >= 0)
					continue;
			}
			default: // Units assigned to a plan.
			{
				if (kbUnitGetPlanID(unitID) >= 0)
					continue;
			}
		}

		if (kbUnitIsType(unitID, cUnitTypeSettlerWagon))
			pop = 2;
		else
			pop = 1;

		resourceID = kbUnitGetTargetUnitID(unitID);
		forceGathererRecovery =
			(recoveryAvoidTargetID >= 0) && (resourceID == recoveryAvoidTargetID);
		currentNaturalActionID =
			getRecoverableNaturalTargetAction(resourceID);
		currentNaturalResourceType =
			getRecoverableNaturalResourceType(
				resourceID, currentNaturalActionID);
		bypassCurrentNaturalTarget =
			(currentNaturalActionID == actionID) &&
			(forceGathererRecovery ||
			(currentNaturalResourceType < 0));
		if (resourceID >= 0)
		{
			// Currently on crates/berries/mines/mill units/estate units.
			// and *not* assigned to a plan.
			if (actionID == cActionTypeGather)
			{
				// Valid productive assignments remain untouched. Only the
				// specifically recovered (or now-invalid) natural target falls
				// through to fresh selection.
				if (bypassCurrentNaturalTarget == false)
				{
					if ((currentNaturalActionID == cActionTypeGather) &&
						(currentNaturalResourceType == cResourceGold))
					{
						if (numGoldVills > 0)
						{
							numGoldVills = numGoldVills - pop;
							continue;
						}
					}
					else if ((currentNaturalActionID == cActionTypeGather) &&
						(currentNaturalResourceType == cResourceFood))
					{
						if (numFoodVills > 0)
						{
							numFoodVills = numFoodVills - pop;
							continue;
						}
					}
					// 'deHacienda' is listed as '<unittype>Gold</unittype>', so we need to account for this first.
					else if (kbUnitIsType(resourceID, cUnitTypedeHacienda))
					{
						if (aiUnitGetTactic(resourceID) == cTacticHaciendaCoin)
						{
							if (numGoldVills > 0)
							{
								numGoldVills = numGoldVills - pop;
								continue;
							}
						}
						else if (numFoodVills > 0) // Then it must be food tactic.
						{
							numFoodVills = numFoodVills - pop;
							continue;
						}
					}
					else if (kbUnitIsType(resourceID, cUnitTypeGold))
					{
						if (numGoldVills > 0)
						{
							numGoldVills = numGoldVills - pop;
							continue;
						}
					}
					// 'ypRicePaddy' and 'deField' are listed as '<unittype>Food</unittype>' in protoy.xml
					else if (kbUnitIsType(resourceID, cUnitTypeypRicePaddy) || kbUnitIsType(resourceID, cUnitTypedeField))
					{	// NOTE: I do not think there are 'team' rice paddy or field cards, unlike the Hacienda.
						// Otherwise I should distinguish paddy from field tactics by their constant ID in the odd case
						// that some civ gets a one of these from an ally shipment and cannot evaluate this.
						if (aiUnitGetTactic(resourceID) == gFarmGoldTactic)
						{
							if (numGoldVills > 0)
							{
								numGoldVills = numGoldVills - pop;
								continue;
							}
						}
						else if (numFoodVills > 0) // Then it must be food tactic.
						{
							numFoodVills = numFoodVills - pop;
							continue;
						}
					}
					// Mills and Farms.
					else if (kbUnitIsType(resourceID, cUnitTypeFood))
					{
						if (numFoodVills > 0)
						{
							numFoodVills = numFoodVills - pop;
							continue;
						}
					}
				}
			}
			// Currently hunting/chopping.
			else if (actionID == cActionTypeHunting)
			{
				if (kbUnitIsType(resourceID, cUnitTypeTree))
				{
					if ((bypassCurrentNaturalTarget == false) &&
						(numWoodVills > 0))
					{
						numWoodVills = numWoodVills - pop;
						continue;
					}
				}
				else if (isUsableHuntTarget(resourceID))
				{
					if ((numFoodVills > 0) && (forceGathererRecovery == false))
					{
						numFoodVills = numFoodVills - pop;
						continue;	
					}
				}
			}
		}

		location = kbUnitGetPosition(unitID);
		selectionNow = xsGetTime();
		foodID = -1;
		foodIndex = -1;
		foodDistance = 9999.0;
		woodID = -1;
		woodIndex = -1;
		woodDistance = 9999.0;
		goldID = -1;
		goldIndex = -1;
		goldDistance = 9999.0;
		foodFromDecayingArray = false;

		// ========================================
		// Food Resources.
		//
		if (numFoodVills > 0)
		{
			// ========================================
			// Check for decaying huntables first.
			resourceID = -1;
			// Find a starting comparison that does not have too
			// many workers.
			for (tempIndex = 0; < arrayGetSize(gDecayingAnimals))
			{	// Should not matter for Japanese as resourceID will always be -1.
				resourceID = arrayGetInt(gDecayingAnimals, tempIndex);
				if (resourceID == recoveryAvoidTargetID)
				{
					resourceID = -1;
					continue;
				}
				if (isUsableHuntTarget(resourceID) == false)
				{
					resourceID = -1;
					continue;
				}
				decayingMaximumCapacity = 5;
				if (kbUnitIsType(resourceID, cUnitTypeHerdable))
					decayingMaximumCapacity = 4;
				decayingCapacity = getHuntTargetWorkerCapacity(
					resourceID, false, decayingMaximumCapacity, selectionNow);
				if (arrayGetInt(gDecayingNumWorkers, tempIndex) >= decayingCapacity)
				{
					traceHuntAssignment(-1, resourceID, false,
						decayingCapacity, 1, "full");
					resourceID = -1;
					continue;
				}
				break;
			}

			if (resourceID >= 0)
			{
				closestResourceID = resourceID;
				closestResourceIndex = tempIndex;
				closestDistance = getDistance(
					location,
					kbUnitGetPosition(closestResourceID)
				);

				for (j = tempIndex + 1; < arrayGetSize(gDecayingAnimals))
				{
					resourceID = arrayGetInt(gDecayingAnimals, j);
					if (resourceID == recoveryAvoidTargetID)
						continue;
					if (isUsableHuntTarget(resourceID) == false)
						continue;
					decayingMaximumCapacity = 5;
					if (kbUnitIsType(resourceID, cUnitTypeHerdable))
						decayingMaximumCapacity = 4;
					decayingCapacity = getHuntTargetWorkerCapacity(
						resourceID, false, decayingMaximumCapacity, selectionNow);
					if (arrayGetInt(gDecayingNumWorkers, j) >= decayingCapacity)
					{
						traceHuntAssignment(-1, resourceID, false,
							decayingCapacity, 1, "full");
						continue;
					}

					tempDistance = getDistance(location, kbUnitGetPosition(resourceID));
					if (tempDistance < closestDistance)
					{
						closestResourceID = resourceID;
						closestResourceIndex = j;
						closestDistance = tempDistance;
					}

					if (closestDistance < 12.0)
						break;	// This one is close enough.
				}
				foodID = closestResourceID;
				foodIndex = closestResourceIndex;
				foodDistance = closestDistance;
				foodFromDecayingArray = true;
				goto PrioritizeDecayingAnimal;
			}
			//
			// End of check for decaying huntables.
			// ========================================

			// ========================================
			// All other land food resources.
			//
			resourceID = -1;
			// Find a starting comparison that does not have too
			// many workers.
			for (tempIndex = 0; < arrayGetSize(gFoodResources))
			{
				resourceID = arrayGetInt(gFoodResources, tempIndex);
				if (resourceID == recoveryAvoidTargetID)
				{
					resourceID = -1;
					continue;
				}
				candidateActionID =
					getRecoverableNaturalTargetAction(resourceID);
				candidateResourceType =
					getRecoverableNaturalResourceType(
						resourceID, candidateActionID);
				candidateCapacity =
					arrayGetInt(gMaxFoodWorkers, tempIndex);
				if (candidateActionID >= 0)
				{
					if (candidateResourceType != cResourceFood)
					{
						resourceID = -1;
						continue;
					}
					candidateCapacity =
						getRecoverableNaturalTargetWorkerCapacity(
							resourceID, selectionNow);
				}
				if ((candidateCapacity < 1) ||
					(arrayGetInt(gFoodNumWorkers, tempIndex) >=
					candidateCapacity))
				{
					if (kbUnitIsType(resourceID, cUnitTypeHuntable) ||
						kbUnitIsType(resourceID, cUnitTypeHerdable))
					{
						traceHuntAssignment(-1, resourceID, true,
							candidateCapacity, 1, "full");
					}
					resourceID = -1;
					continue;
				}
				if (kbUnitGetPosition(resourceID) == cInvalidVector)
				{
					resourceID = -1;
					continue;
				}
				if ((kbUnitIsType(resourceID, cUnitTypeHuntable) ||
					kbUnitIsType(resourceID, cUnitTypeHerdable)) &&
					(isUsableHuntTarget(resourceID) == false))
				{
					resourceID = -1;
					continue;
				}
				break;
			}

			if (resourceID >= 0)
			{
				closestResourceID = resourceID;
				closestResourceIndex = tempIndex;
				closestDistance = getDistance(
					location,
					kbUnitGetPosition(closestResourceID)
				);

				for (j = tempIndex + 1; < arrayGetSize(gFoodResources))
				{
					resourceID = arrayGetInt(gFoodResources, j);
					if (resourceID == recoveryAvoidTargetID)
						continue;
					candidateActionID =
						getRecoverableNaturalTargetAction(resourceID);
					candidateResourceType =
						getRecoverableNaturalResourceType(
							resourceID, candidateActionID);
					candidateCapacity =
						arrayGetInt(gMaxFoodWorkers, j);
					if (candidateActionID >= 0)
					{
						if (candidateResourceType != cResourceFood)
							continue;
						candidateCapacity =
							getRecoverableNaturalTargetWorkerCapacity(
								resourceID, selectionNow);
					}
					if ((candidateCapacity < 1) ||
						(arrayGetInt(gFoodNumWorkers, j) >=
						candidateCapacity))
					{
						if (kbUnitIsType(resourceID, cUnitTypeHuntable) ||
							kbUnitIsType(resourceID, cUnitTypeHerdable))
						{
							traceHuntAssignment(-1, resourceID, true,
								candidateCapacity, 1, "full");
						}
						continue;
					}
					if (kbUnitGetPosition(resourceID) == cInvalidVector)
						continue;
					if ((kbUnitIsType(resourceID, cUnitTypeHuntable) ||
						kbUnitIsType(resourceID, cUnitTypeHerdable)) &&
						(isUsableHuntTarget(resourceID) == false))
					{
						continue;
					}

					tempDistance = getDistance(location, kbUnitGetPosition(resourceID));
					if (tempDistance < closestDistance)
					{
						closestResourceID = resourceID;
						closestResourceIndex = j;
						closestDistance = tempDistance;
					}

					if (closestDistance < 12.0)
						break;	// This one is close enough.
				}
				foodID = closestResourceID;
				foodIndex = closestResourceIndex;
				foodDistance = closestDistance;
				foodFromDecayingArray = false;
			}
			//
			// End of check for all other land food resources.
			// ========================================
		}
		//
		// End Food Resources.
		// ========================================

		// If we found a decaying huntable to work, we jump to this point from "goto",
		// bypassing the live huntable check.
		label PrioritizeDecayingAnimal;

		// ========================================
		// Wood Resources.
		//
		if (numWoodVills > 0)
		{
			resourceID = -1;
			// Find a starting comparison that does not have too
			// many workers.
			for (tempIndex = 0; < arrayGetSize(gWoodResources))
			{
				resourceID = arrayGetInt(gWoodResources, tempIndex);
				if (resourceID == recoveryAvoidTargetID)
				{
					resourceID = -1;
					continue;
				}
				candidateActionID =
					getRecoverableNaturalTargetAction(resourceID);
				candidateResourceType =
					getRecoverableNaturalResourceType(
						resourceID, candidateActionID);
				candidateCapacity = 5;
				if (kbUnitIsType(resourceID, cUnitTypeypGroveBuilding))
					candidateCapacity = 25;
				else if (candidateActionID >= 0)
				{
					if (candidateResourceType != cResourceWood)
					{
						resourceID = -1;
						continue;
					}
					candidateCapacity =
						getRecoverableNaturalTargetWorkerCapacity(
							resourceID, selectionNow);
				}
				if ((candidateCapacity < 1) ||
					(arrayGetInt(gWoodNumWorkers, tempIndex) >=
					candidateCapacity))
				{
					resourceID = -1;
					continue;
				}
				if (kbUnitGetPosition(resourceID) == cInvalidVector)
				{
					resourceID = -1;
					continue;
				}
				break;
			}

			if (resourceID >= 0)
			{
				closestResourceID = resourceID;
				closestResourceIndex = tempIndex;
				closestDistance = getDistance(
					location,
					kbUnitGetPosition(closestResourceID)
				);

				for (j = tempIndex + 1; < arrayGetSize(gWoodResources))
				{
					resourceID = arrayGetInt(gWoodResources, j);
					if (resourceID == recoveryAvoidTargetID)
						continue;
					candidateActionID =
						getRecoverableNaturalTargetAction(resourceID);
					candidateResourceType =
						getRecoverableNaturalResourceType(
							resourceID, candidateActionID);
					candidateCapacity = 5;
					if (kbUnitIsType(resourceID, cUnitTypeypGroveBuilding))
						candidateCapacity = 25;
					else if (candidateActionID >= 0)
					{
						if (candidateResourceType != cResourceWood)
							continue;
						candidateCapacity =
							getRecoverableNaturalTargetWorkerCapacity(
								resourceID, selectionNow);
					}
					if ((candidateCapacity < 1) ||
						(arrayGetInt(gWoodNumWorkers, j) >=
						candidateCapacity))
						continue;
					if (kbUnitGetPosition(resourceID) == cInvalidVector)
						continue;

					tempDistance = getDistance(location, kbUnitGetPosition(resourceID));
					if (tempDistance < closestDistance)
					{
						closestResourceID = resourceID;
						closestResourceIndex = j;
						closestDistance = tempDistance;
					}

					if (closestDistance < 12.0)
						break;	// This one is close enough.
				}
				woodID = closestResourceID;
				woodIndex = closestResourceIndex;
				woodDistance = closestDistance;
			}
		}
		//
		// End Wood Resources.
		// ========================================

		// ========================================
		// Gold Resources.
		//
		if (numGoldVills > 0)
		{
			resourceID = -1;
			// Find a starting comparison that does not have too
			// many workers.
			for (tempIndex = 0; < arrayGetSize(gGoldResources))
			{
				resourceID = arrayGetInt(gGoldResources, tempIndex);
				if (resourceID == recoveryAvoidTargetID)
				{
					resourceID = -1;
					continue;
				}
				candidateActionID =
					getRecoverableNaturalTargetAction(resourceID);
				candidateResourceType =
					getRecoverableNaturalResourceType(
						resourceID, candidateActionID);
				candidateCapacity =
					arrayGetInt(gMaxGoldWorkers, tempIndex);
				if (candidateActionID >= 0)
				{
					if (candidateResourceType != cResourceGold)
					{
						resourceID = -1;
						continue;
					}
					candidateCapacity =
						getRecoverableNaturalTargetWorkerCapacity(
							resourceID, selectionNow);
				}
				if ((candidateCapacity < 1) ||
					(arrayGetInt(gGoldNumWorkers, tempIndex) >=
					candidateCapacity))
				{
					resourceID = -1;
					continue;
				}
				if (kbUnitGetPosition(resourceID) == cInvalidVector)
				{
					resourceID = -1;
					continue;
				}
				break;
			}

			if (resourceID >= 0)
			{
				closestResourceID = resourceID;
				closestResourceIndex = tempIndex;
				closestDistance = getDistance(
					location,
					kbUnitGetPosition(closestResourceID)
				);

				for (j = tempIndex + 1; < arrayGetSize(gGoldResources))
				{
					resourceID = arrayGetInt(gGoldResources, j);
					if (resourceID == recoveryAvoidTargetID)
						continue;
					candidateActionID =
						getRecoverableNaturalTargetAction(resourceID);
					candidateResourceType =
						getRecoverableNaturalResourceType(
							resourceID, candidateActionID);
					candidateCapacity =
						arrayGetInt(gMaxGoldWorkers, j);
					if (candidateActionID >= 0)
					{
						if (candidateResourceType != cResourceGold)
							continue;
						candidateCapacity =
							getRecoverableNaturalTargetWorkerCapacity(
								resourceID, selectionNow);
					}
					if ((candidateCapacity < 1) ||
						(arrayGetInt(gGoldNumWorkers, j) >=
						candidateCapacity))
						continue;
					if (kbUnitGetPosition(resourceID) == cInvalidVector)
						continue;

					tempDistance = getDistance(location, kbUnitGetPosition(resourceID));
					if (tempDistance < closestDistance)
					{
						closestResourceID = resourceID;
						closestResourceIndex = j;
						closestDistance = tempDistance;
					}

					if (closestDistance < 12.0)
						break;	// This one is close enough.
				}
				goldID = closestResourceID;
				goldIndex = closestResourceIndex;
				goldDistance = closestDistance;
			}
		}
		//
		// End Gold Resources.
		// ========================================

		candidateInvalid = false;
		if (foodID >= 0)
		{
			if ((foodID == recoveryAvoidTargetID) ||
				(kbUnitGetPosition(foodID) == cInvalidVector))
			{
				candidateInvalid = true;
			}
			candidateActionID =
				getRecoverableNaturalTargetAction(foodID);
			candidateResourceType =
				getRecoverableNaturalResourceType(
					foodID, candidateActionID);
			candidateCapacity = -1;
			candidateWorkerCount = -1;
			if (foodFromDecayingArray == true)
			{
				if ((foodIndex >= 0) &&
					(foodIndex < arrayGetSize(gDecayingNumWorkers)))
				{
					decayingMaximumCapacity = 5;
					if (kbUnitIsType(foodID, cUnitTypeHerdable))
						decayingMaximumCapacity = 4;
					candidateCapacity = getHuntTargetWorkerCapacity(
						foodID, false, decayingMaximumCapacity, selectionNow);
					candidateWorkerCount =
						arrayGetInt(gDecayingNumWorkers, foodIndex);
				}
				else
				{
					candidateInvalid = true;
				}
			}
			else if ((foodIndex >= 0) &&
				(foodIndex < arrayGetSize(gFoodNumWorkers)) &&
				(foodIndex < arrayGetSize(gMaxFoodWorkers)))
			{
				candidateCapacity =
					arrayGetInt(gMaxFoodWorkers, foodIndex);
				candidateWorkerCount =
					arrayGetInt(gFoodNumWorkers, foodIndex);
			}
			else
			{
				candidateInvalid = true;
			}
			if (candidateActionID >= 0)
			{
				if (candidateResourceType != cResourceFood)
					candidateInvalid = true;
				else
					candidateCapacity =
						getRecoverableNaturalTargetWorkerCapacity(
							foodID, selectionNow);
			}
			if ((candidateCapacity < 1) ||
				(candidateWorkerCount >= candidateCapacity))
			{
				candidateInvalid = true;
			}
			if (candidateInvalid == true)
			{
				foodID = -1;
				foodIndex = -1;
				foodDistance = 9999.0;
			}
		}

		candidateInvalid = false;
		if (woodID >= 0)
		{
			if ((woodID == recoveryAvoidTargetID) ||
				(kbUnitGetPosition(woodID) == cInvalidVector) ||
				(woodIndex < 0) ||
				(woodIndex >= arrayGetSize(gWoodNumWorkers)))
			{
				candidateInvalid = true;
			}
			candidateActionID =
				getRecoverableNaturalTargetAction(woodID);
			candidateResourceType =
				getRecoverableNaturalResourceType(
					woodID, candidateActionID);
			candidateCapacity = 5;
			if (kbUnitIsType(woodID, cUnitTypeypGroveBuilding))
				candidateCapacity = 25;
			else if (candidateActionID >= 0)
			{
				if (candidateResourceType != cResourceWood)
					candidateInvalid = true;
				else
					candidateCapacity =
						getRecoverableNaturalTargetWorkerCapacity(
							woodID, selectionNow);
			}
			if (candidateInvalid == false)
				candidateWorkerCount =
					arrayGetInt(gWoodNumWorkers, woodIndex);
			else
				candidateWorkerCount = candidateCapacity;
			if ((candidateCapacity < 1) ||
				(candidateWorkerCount >= candidateCapacity))
			{
				candidateInvalid = true;
			}
			if (candidateInvalid == true)
			{
				woodID = -1;
				woodIndex = -1;
				woodDistance = 9999.0;
			}
		}

		candidateInvalid = false;
		if (goldID >= 0)
		{
			if ((goldID == recoveryAvoidTargetID) ||
				(kbUnitGetPosition(goldID) == cInvalidVector) ||
				(goldIndex < 0) ||
				(goldIndex >= arrayGetSize(gGoldNumWorkers)) ||
				(goldIndex >= arrayGetSize(gMaxGoldWorkers)))
			{
				candidateInvalid = true;
			}
			candidateActionID =
				getRecoverableNaturalTargetAction(goldID);
			candidateResourceType =
				getRecoverableNaturalResourceType(
					goldID, candidateActionID);
			if (candidateInvalid == false)
			{
				candidateCapacity =
					arrayGetInt(gMaxGoldWorkers, goldIndex);
				candidateWorkerCount =
					arrayGetInt(gGoldNumWorkers, goldIndex);
			}
			else
			{
				candidateCapacity = 0;
				candidateWorkerCount = 0;
			}
			if (candidateActionID >= 0)
			{
				if (candidateResourceType != cResourceGold)
					candidateInvalid = true;
				else
					candidateCapacity =
						getRecoverableNaturalTargetWorkerCapacity(
							goldID, selectionNow);
			}
			if ((candidateCapacity < 1) ||
				(candidateWorkerCount >= candidateCapacity))
			{
				candidateInvalid = true;
			}
			if (candidateInvalid == true)
			{
				goldID = -1;
				goldIndex = -1;
				goldDistance = 9999.0;
			}
		}

		if ((foodID < 0) && (woodID < 0) && (goldID < 0))
		{
			if (forceGathererRecovery == true)
				aiTaskUnitMove(unitID, gHomeBase);
			continue;
		}

		if (foodDistance < woodDistance) // Food is closer than Wood.
		{
			if (foodDistance < goldDistance) // Food is closer than Gold.
			{
				if ((foodFromDecayingArray == false) &&
					(kbUnitIsType(foodID, cUnitTypeHuntable) == true) &&
					(kbUnitGetMaximumHitpoints(foodID) > 0.0) &&
					(kbUnitGetCurrentHitpoints(foodID) >= kbUnitGetMaximumHitpoints(foodID)))
				{
					// Swedish should try to herd huntables toward nearby Torps.
					if (cMyCiv == cCivDESwedish)
						targetLocation = kbUnitGetPosition(
							getClosestUnit(cUnitTypedeTorp, cMyID,
							cUnitStateABQ, kbUnitGetPosition(foodID), 45.0)
						);
					// African civs should try to herd huntables toward nearby Granaries.
					else if (civIsAfrican())
						targetLocation = kbUnitGetPosition(
							getClosestUnit(cUnitTypedeGranary, cMyID,
							cUnitStateABQ, kbUnitGetPosition(foodID), 45.0)
						);

					if (targetLocation == cInvalidVector)
						targetLocation = gHomeBase;
					aiTaskUnitMove(unitID, (targetLocation + (kbUnitGetPosition(foodID) - targetLocation) +
						xsVectorNormalize(kbUnitGetPosition(foodID) - targetLocation) * 16.0));
					aiTaskUnitWork(unitID, foodID, true);
				}
				else
				{
					aiTaskUnitWork(unitID, foodID);
				}

				// The decaying and ordinary food branches share this tasking block.
				// Update the counter that belongs to the array which supplied foodID.
				if (foodFromDecayingArray == true)
				{
					if ((foodIndex >= 0) && (foodIndex < arrayGetSize(gDecayingNumWorkers)))
					{
						arraySetInt(gDecayingNumWorkers, foodIndex,
							arrayGetInt(gDecayingNumWorkers, foodIndex) + 1);
					}
					else
					{
						debugEvent("ECO-INVARIANT", "invalid decaying food index " + foodIndex +
							" for resource " + foodID);
					}
				}
				else
				{
					if ((foodIndex >= 0) && (foodIndex < arrayGetSize(gFoodNumWorkers)))
					{
						arraySetInt(gFoodNumWorkers, foodIndex,
							arrayGetInt(gFoodNumWorkers, foodIndex) + 1);
					}
					else
					{
						debugEvent("ECO-INVARIANT", "invalid ordinary food index " + foodIndex +
							" for resource " + foodID);
					}
				}

				assignedAnimalTarget =
					(kbUnitIsType(foodID, cUnitTypeHuntable) == true) ||
					(kbUnitIsType(foodID, cUnitTypeHerdable) == true);
				if (assignedAnimalTarget == true)
				{
					assignedLiveTarget = (foodFromDecayingArray == false);
					reservationResult =
						manageHuntAssignmentReservations(foodID, unitID, xsGetTime());
					if (foodFromDecayingArray == true)
					{
						decayingMaximumCapacity = 5;
						if (kbUnitIsType(foodID, cUnitTypeHerdable))
							decayingMaximumCapacity = 4;
						assignmentCapacity = getHuntTargetWorkerCapacity(
							foodID, false, decayingMaximumCapacity, selectionNow);
					}
					else
					{
						assignmentCapacity =
							getRecoverableNaturalTargetWorkerCapacity(
								foodID, selectionNow);
					}
					traceHuntAssignment(unitID, foodID, assignedLiveTarget,
						assignmentCapacity, 0, "assign");
				}
				numFoodVills = numFoodVills - pop;
			}
			else // Gold is closer than Food.
			{
				aiTaskUnitWork(unitID, goldID);
				// Update the number of workers on the gold unit.
				arraySetInt(gGoldNumWorkers, goldIndex, (arrayGetInt(gGoldNumWorkers, goldIndex) + 1));
				numGoldVills = numGoldVills - pop;
			}
		}
		else if (woodDistance < goldDistance) // Wood is closer than both Food and Gold.
		{
			numWoodVills = numWoodVills - pop;
			aiTaskUnitWork(unitID, woodID);
			// Help vills that sometimes get stuck.
			aiTaskUnitMove(unitID, kbUnitGetPosition(woodID) + gDirection_UP, true);

			// Update the number of workers on the wood unit.
			arraySetInt(gWoodNumWorkers, woodIndex, (arrayGetInt(gWoodNumWorkers, woodIndex) + 1));
		}
		else // Gold is closer than both Food and Wood.
		{
			numGoldVills = numGoldVills - pop;
			aiTaskUnitWork(unitID, goldID);

			// Update the number of workers on the gold unit.
			arraySetInt(gGoldNumWorkers, goldIndex, (arrayGetInt(gGoldNumWorkers, goldIndex) + 1));
		}
	}
}

rule taskFishingBoats
inactive
minInterval 5
{
	static int fishingBoatQuery = -1;
	if (fishingBoatQuery < 0)
	{
		fishingBoatQuery = kbUnitQueryCreate("Fishing Boat Query");
		kbUnitQuerySetPlayerID(fishingBoatQuery, cMyID);
		kbUnitQuerySetPlayerRelation(fishingBoatQuery, -1);
		kbUnitQuerySetState(fishingBoatQuery, cUnitStateAlive);
		kbUnitQuerySetIgnoreKnockedOutUnits(fishingBoatQuery, true);
		kbUnitQuerySetUnitType(fishingBoatQuery, cUnitTypeAbstractFishingBoat);
	}
	kbUnitQueryResetResults(fishingBoatQuery);
	int numResults = kbUnitQueryExecute(fishingBoatQuery);

	int numFoodBoats = 0;
	int numGoldBoats = 0;
	int unitID = -1;
	int actionID = -1;
	int resourceID = -1;
	int planID = -1;
	vector location = cInvalidVector;
	int closestResourceID = -1;
	float foodDistance = 0.0;
	float goldDistance = 0.0;
	int foodID = -1;
	int goldID = -1;
	vector targetLocation = cInvalidVector;

	numFoodBoats = numResults * (aiGetResourcePercentage(cResourceFood) / 
		(aiGetResourcePercentage(cResourceFood) + aiGetResourcePercentage(cResourceGold)));
	numGoldBoats = numResults - numFoodBoats;

	if (numFoodBoats > 0)
		updateFoodFishBreakdown();
	if (numGoldBoats > 0)
		updateGoldFishBreakdown();

	for (i = 0; < numResults)
	{
		unitID = kbUnitQueryGetResult(fishingBoatQuery, i);
		actionID = kbUnitGetActionType(unitID);
		switch (actionID)
		{
			case cActionTypeMove: // Currently moving.
			case cActionTypeMoveByGroup: // Currently moving.
				continue;
			default: // Boats assigned to a plan.
			{
				if (kbUnitGetPlanID(unitID) >= 0)
					continue;
			}
		}
		resourceID = kbUnitGetTargetUnitID(unitID);
		if (resourceID >= 0)
		{
			if (actionID == cActionTypeGather)
			{
				if (kbUnitIsType(resourceID, cUnitTypeAbstractFish))
				{
					if (numFoodBoats > 0)
					{
						numFoodBoats--;
						continue;
					}
				}
				else if (kbUnitIsType(resourceID, cUnitTypeAbstractWhale))
				{
					if (numGoldBoats > 0)
					{
						numGoldBoats--;
						continue;
					}
				}
			}
		}

		location = kbUnitGetPosition(unitID);
		foodDistance = 9999.0;
		goldDistance = 9999.0;

		if (numFoodBoats > 0)
		{
			resourceID = arrayGetInt(gFoodFishResources, 0);
			if (resourceID >= 0)
			{
				closestResourceID = resourceID;
				for (j = 1; < arrayGetSize(gFoodFishResources))
				{
					resourceID = arrayGetInt(gFoodFishResources, j);
					if (getDistance(location, kbUnitGetPosition(resourceID)) < getDistance(location, kbUnitGetPosition(closestResourceID)))
						closestResourceID = resourceID;
				}
				foodDistance = getDistance(location, kbUnitGetPosition(closestResourceID));
				foodID = closestResourceID;
			}
		}

		if (numGoldBoats > 0)
		{
			resourceID = arrayGetInt(gGoldFishResources, 0);
			if (resourceID >= 0)
			{
				closestResourceID = resourceID;
				for (j = 1; < arrayGetSize(gGoldFishResources))
				{
					resourceID = arrayGetInt(gGoldFishResources, j);
					if (getDistance(location, kbUnitGetPosition(resourceID)) < getDistance(location, kbUnitGetPosition(closestResourceID)))
						closestResourceID = resourceID;
				}
				goldDistance = getDistance(location, kbUnitGetPosition(closestResourceID));
				goldID = closestResourceID;
			}
		}

		if (foodDistance < goldDistance) // Food is closer than Gold.
		{
			aiTaskUnitWork(unitID, foodID);
			numFoodBoats--;
		}
		else
		{
			aiTaskUnitWork(unitID, goldID);
			numGoldBoats--;
		}
	}
}

int getClosestTreeID(vector location = cInvalidVector)
{
	int treeQuery = createSimpleUnitQuery(cUnitTypeTree, cPlayerRelationAny, cUnitStateAny, location, 45.0);
	kbUnitQuerySetAscendingSort(treeQuery, true);
	kbUnitQueryResetResults(treeQuery);
	if (kbUnitQueryExecute(treeQuery) > 0)
		return(kbUnitQueryGetResult(treeQuery, 0));

	return(-1);
}

rule architectManager
inactive
minInterval 2
{
	int numArchitects = kbUnitCount(cMyID, cUnitTypedeArchitect, cUnitStateAlive);

	if (cMyCiv == cCivDEItalians && kbGetAge() >= cAge2)
	{
		static int architectMaintainPlan = -1;
		int numWanted = (kbGetAge() >= cAge3) ? kbGetBuildLimit(cMyID, cUnitTypedeArchitect) : 2;
		if (architectMaintainPlan < 0)
			architectMaintainPlan = createSimpleMaintainPlan(cUnitTypedeArchitect, numWanted, true);
		else
			aiPlanSetVariableInt(architectMaintainPlan, cTrainPlanNumberToMaintain, 0, numWanted);
	}

	if (numArchitects == 0)
		return;

	int architectID = -1;
	int architectQuery = createSimpleUnitQuery(cUnitTypedeArchitect, cMyID, cUnitStateAlive);
	numArchitects = kbUnitQueryExecute(architectQuery);
	int previousIndex = 0;
	int planID = -1;
	int bestPlanID = -1;
	int bestPlanPrio = -1;

	for (i = 0; < numArchitects)
	{
		architectID = kbUnitQueryGetResult(architectQuery, i);
		if (kbUnitGetPlanID(architectID) >= 0)
		{
			architectID = -1;
			continue;
		}
	}

	if (architectID >= 0)
	{
		for (index = 0; < aiPlanGetNumber(cPlanBuild, cPlanStateNone, false))
		{
			planID = aiPlanGetIDByIndex(cPlanBuild, cPlanStateNone, false, index);

			if (aiPlanGetUserVariableInt(planID, cBuildPlanBuilderTypeID, 0) != cUnitTypedeArchitect)
			{
				continue;
			}

			debugBuildings("Considering for architect: " + aiPlanGetName(planID));

			int prio = aiPlanGetDesiredPriority(planID);
			if (prio > bestPlanPrio)
			{
				bestPlanID = planID;
				bestPlanPrio = prio;
			}
		}

		if (bestPlanID >= 0)
		{
			aiPlanAddUnitType(bestPlanID, cUnitTypedeArchitect, 1, 1, 1);
			aiPlanAddUnit(bestPlanID, architectID);
			aiPlanSetActive(bestPlanID, true);
			debugBuildings("Activating " + aiPlanGetName(planID) + " for architect construction.");
		}
		else
		{
			if (kbUnitCount(cMyID, gTowerUnit, cUnitStateABQ) < kbGetBuildLimit(cMyID, gTowerUnit))
			{
				debugBuildings("Queueing tower build plan for architect construction.");
				createArchitectBuildPlan(gTowerUnit, 45, gHomeBase);
			}
			else
			{
				debugBuildings("Nothing to build, looking for tree.");
				int treeID = getClosestTreeID(gHomeBase);
				if (treeID >= 0)
					aiTaskUnitWork(architectID, treeID);
				else
					aiTaskUnitMove(architectID, gHomeBase + gDirection_DOWN * 5.0);
			}
		}
	}
}

rule taskAbuns
inactive
minInterval 10
{
	int mode = 0;
	int numAbuns = -1;
	if (gHealerPlan >= 0 && aiPlanGetState(gHealerPlan) < 0)
	{
		debugEvent("MIL-HEALER", "recover stale Abun plan id=" + gHealerPlan);
		gHealerPlan = -1;
	}
	else if (gHealerPlan >= 0 &&
		(aiPlanGetType(gHealerPlan) != cPlanCombat ||
		aiPlanGetVariableInt(gHealerPlan, cCombatPlanCombatType, 0) != cCombatPlanCombatTypeDefend))
	{
		debugEvent("MIL-INVARIANT", "replace invalid Abun plan id=" + gHealerPlan +
			" type=" + aiPlanGetType(gHealerPlan));
		aiPlanDestroy(gHealerPlan);
		gHealerPlan = -1;
	}
	if (getHomeBaseThreatened())
		mode = 1;
	switch (mode)
	{
		case 0:
		{
			if (kbUnitCount(cMyID, cUnitTypedeMountainMonastery, cUnitStateAlive) < 0)
				break;
			if (gHealerPlan >= 0)
			{
				debugEvent("MIL-HEALER", "destroy emergency Abun plan id=" + gHealerPlan +
					" reason=peaceful-mode");
				aiPlanDestroy(gHealerPlan);
				gHealerPlan = -1;
			}
			int abunQuery = createSimpleUnitQuery(cUnitTypedeAbun);
			numAbuns = kbUnitQueryExecute(abunQuery);
			int abunID = -1;
			int mountainMonasteryID = -1;
			vector location = cInvalidVector;
			for (i = 0; < numAbuns)
			{
				abunID = kbUnitQueryGetResult(abunQuery, i);
				location = kbUnitGetPosition(abunID);
				for (j = 0; < kbUnitCount(cMyID, cUnitTypedeMountainMonastery, cUnitStateAlive))
				{
					mountainMonasteryID = getUnitByLocation(cUnitTypedeMountainMonastery, cMyID,
						cUnitStateAlive, location, -1, j);
					if (kbUnitGetResourceAmount(mountainMonasteryID, cResourceGold) < 1.0)
					{
						mountainMonasteryID = -1;
						continue;
					}
					if (kbUnitGetNumberWorkers(mountainMonasteryID) == 20)
					{
						mountainMonasteryID = -1;
						continue;
					}
					break;
				}
				if (mountainMonasteryID >= 0)
					aiTaskUnitWork(abunID, mountainMonasteryID);
			}
			break;
		}
		case 1:
		{
			numAbuns = kbUnitCount(cMyID, cUnitTypedeAbun, cUnitStateAlive);
			int mainBaseID = kbBaseGetMainID(cMyID);
			if (mainBaseID < 0)
			{
				debugEvent("MIL-INVARIANT", "cannot create Abun emergency plan: no main base");
				break;
			}
			vector gatherPoint = kbBaseGetMilitaryGatherPoint(cMyID, mainBaseID);
			vector homePosition = kbBaseGetLocation(cMyID, mainBaseID);
			if (gatherPoint == cInvalidVector)
			{
				gatherPoint = gHomeBase;
			}
			if (homePosition == cInvalidVector)
			{
				homePosition = gHomeBase;
			}

			if (gHealerPlan < 0)
			{
				gHealerPlan = aiPlanCreate("Abun Defend Plan", cPlanCombat);
				if (gHealerPlan < 0)
				{
					debugEvent("MIL-INVARIANT", "failed to create Abun cPlanCombat emergency plan");
					break;
				}
				aiPlanSetVariableInt(gHealerPlan, cCombatPlanCombatType, 0, cCombatPlanCombatTypeDefend);
				aiPlanSetVariableInt(gHealerPlan, cCombatPlanTargetMode, 0, cCombatPlanTargetModeBase);
				aiPlanSetVariableInt(gHealerPlan, cCombatPlanTargetPlayerID, 0, cMyID);
				aiPlanSetVariableInt(gHealerPlan, cCombatPlanTargetBaseID, 0, mainBaseID);
				aiPlanSetVariableVector(gHealerPlan, cCombatPlanTargetPoint, 0, gatherPoint);
				aiPlanSetVariableVector(gHealerPlan, cCombatPlanGatherPoint, 0, gatherPoint);
				aiPlanSetVariableFloat(gHealerPlan, cCombatPlanTargetEngageRange, 0,
					cvDefenseReflexRadiusActive);
				aiPlanSetVariableFloat(gHealerPlan, cCombatPlanGatherDistance, 0, 10.0);
				aiPlanSetVariableInt(gHealerPlan, cCombatPlanRefreshFrequency, 0, 1000);
				aiPlanSetBaseID(gHealerPlan, mainBaseID);
				aiPlanSetInitialPosition(gHealerPlan, homePosition);
				aiPlanSetUnitStance(gHealerPlan, cUnitStanceDefensive);
				aiPlanAddUnitType(gHealerPlan, cUnitTypedeAbun, numAbuns, numAbuns, numAbuns);
				aiPlanSetDesiredPriority(gHealerPlan, 99);
				if (aiPlanSetActive(gHealerPlan) == false)
				{
					debugEvent("MIL-INVARIANT", "failed to activate Abun emergency plan id=" + gHealerPlan);
					aiPlanDestroy(gHealerPlan);
					gHealerPlan = -1;
					break;
				}
				debugEvent("MIL-HEALER", "created Abun cPlanCombat/Defend id=" + gHealerPlan +
					" base=" + mainBaseID + " abuns=" + numAbuns);
			}
			else
			{
				aiPlanSetVariableInt(gHealerPlan, cCombatPlanTargetBaseID, 0, mainBaseID);
				aiPlanSetVariableVector(gHealerPlan, cCombatPlanTargetPoint, 0, gatherPoint);
				aiPlanSetVariableVector(gHealerPlan, cCombatPlanGatherPoint, 0, gatherPoint);
				aiPlanAddUnitType(gHealerPlan, cUnitTypedeAbun, numAbuns, numAbuns, numAbuns);
			}

			break;
		}
	}

}

rule crateMonitor
inactive
minInterval 5
{
	static int cratePlanID = -1;
	int numCrates = -1;
	int numUnits = -1;
	int unitID = -1;

	int crateQuery = createSimpleUnitQuery(cUnitTypeAbstractResourceCrate, cPlayerRelationAny, cUnitStateAlive, gHomeBase, 25.0);
	kbUnitQuerySetAscendingSort(crateQuery, true);
	kbUnitQueryExecute(crateQuery);
	numCrates = kbUnitQueryNumberResults(crateQuery);

	if (numCrates < 1)
	{
		aiPlanDestroy(cratePlanID);
		cratePlanID = -1;
		return;
	}

	if (cratePlanID < 0)
	{	// Initialize the plan
		cratePlanID = aiPlanCreate("Main Base Crate", cPlanReserve);
		aiPlanSetDesiredPriority(cratePlanID, 99);
		aiPlanSetActive(cratePlanID, true);
	}
	aiPlanAddUnitType(cratePlanID, cUnitTypeLogicalTypeSettlerBuildLimit, 1, numCrates, numCrates);
	if (cMyCiv == cCivGermans && kbGetAge() == cAge1)
		aiPlanAddUnitType(cratePlanID, cUnitTypeLogicalTypeSettlerBuildLimit, 1, numCrates / 2, numCrates / 2);


	numUnits = aiPlanGetNumberUnits(cratePlanID, cUnitTypeLogicalTypeSettlerBuildLimit);
	for (i = 0; < numUnits)
	{
		if (kbUnitQueryNumberResults(crateQuery) > i) // This should always be the case.
		{
			unitID = aiPlanGetUnitByIndex(cratePlanID, i);
			aiTaskUnitWork(unitID, kbUnitQueryGetResult(crateQuery, i));
		}
	}
}

rule startingCrates
inactive
minInterval 1
{
	// Don't check for starting crates/herdables until our Town Center is built.
	if (kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive) == 0)
	{
		if (kbUnitCount(cMyID, cUnitTypeCoveredWagon, cUnitStateAlive) > 0 ||
			kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateABQ) > 0)
			return;
	}

	// Let villagers auto-gather starting crates that they need for villager production.
	// For Africans, let them auto-gather the first herdable.
	int numCrates = -1;
	int crateType = -1;
	switch (cMyCiv)
	{
		case cCivDutch:
		{
			crateType = cUnitTypeAbstractCoinCrate;
			break;
		}
		case cCivIndians:
		{
			crateType = cUnitTypeAbstractWoodCrate;
			break;
		}
		default:
		{
			crateType = cUnitTypeAbstractFoodCrate;
			break;
		}
	}

	int crateQuery = createSimpleUnitQuery(crateType, cMyID, cUnitStateAlive, gHomeBase, 25.0);
	kbUnitQuerySetAscendingSort(crateQuery, true);
	numCrates = kbUnitQueryExecute(crateQuery);

	// Vills will be autogathering our crates. Let them finish.
	if (numCrates > 0)
		return;

	if (civIsAfrican() == true)
	{	// Wait until the first slain cattle is half gathered, then proceed.
		int slainCattleID = getClosestUnit(cUnitTypeHerdable, 0, cUnitStateDead, gHomeBase, 15.0);
		if (slainCattleID >= 0)
		{
			if (kbUnitGetResourceAmount(slainCattleID, cResourceFood) > kbUnitGetCarryCapacity(slainCattleID, cResourceFood) * 0.5)
				return;
		}
	}

	xsEnableRule("crateMonitor");
	xsEnableRule("taskVillagers");
	taskVillagers();
	if (gGoodFishingMap == true)
	{
		xsEnableRule("taskFishingBoats");
	}

	xsDisableSelf();
}

//==============================================================================
// updategGarrisonableBuilding
//==============================================================================
void updategGarrisonableBuilding(void)
{
	int numberResults = 0;
	arrayResetSelf(gGarrisonableBuilding);
	if (gGarrisonableBuildingQuery < 0)
	{
		gGarrisonableBuildingQuery = kbUnitQueryCreate("Garrison Buildings Query");
		kbUnitQuerySetPlayerID(gGarrisonableBuildingQuery, cMyID);
		kbUnitQuerySetPlayerRelation(gGarrisonableBuildingQuery, -1);
		kbUnitQuerySetState(gGarrisonableBuildingQuery, cUnitStateAlive);
		kbUnitQuerySetIgnoreKnockedOutUnits(gGarrisonableBuildingQuery, true);
	}
	kbUnitQueryResetResults(gGarrisonableBuildingQuery);
	kbUnitQuerySetUnitType(gGarrisonableBuildingQuery, cUnitTypeTownCenter);
	kbUnitQueryExecute(gGarrisonableBuildingQuery);
	kbUnitQuerySetUnitType(gGarrisonableBuildingQuery, cUnitTypeOutpost);
	kbUnitQueryExecute(gGarrisonableBuildingQuery);
	if (cMyCiv == cCivChinese)
	{
		kbUnitQuerySetUnitType(gGarrisonableBuildingQuery, cUnitTypeypVillage);
		kbUnitQueryExecute(gGarrisonableBuildingQuery);
	}
	numberResults = kbUnitQueryNumberResults(gGarrisonableBuildingQuery);

	for (i = 0; < numberResults)
		arrayPushInt(gGarrisonableBuilding, kbUnitQueryGetResult(gGarrisonableBuildingQuery, i));
}

//==============================================================================
//
// villagerRetreat
//
// - Send threatened villagers to a garrisonable building.
//
//==============================================================================
rule villagerRetreat
active
minInterval 10
{
	if (gVillagerQuery < 0)
		return;

	int unitID = -1;
	int actionID = -1;
	bool nextVillager = false;
	vector location = cInvalidVector;
	int buildingID = -1;
	int closestBuildingID = -1;
	int count = 0;
	updategGarrisonableBuilding();

	for (i = 0; < kbUnitQueryNumberResults(gVillagerQuery))
	{
		unitID = kbUnitQueryGetResult(gVillagerQuery, i);
		actionID = kbUnitGetActionType(unitID);
		location = kbUnitGetPosition(unitID);
		count = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia,
			cUnitStateAlive, location, 30.0);

		if (actionID < 0) // Should signify a villager who is garrisoned inside a building.
		{
			continue;
		}

		if (count <= 4)
			continue;

		buildingID = arrayGetInt(gGarrisonableBuilding, 0);
		if (buildingID >= 0)
		{
			closestBuildingID = buildingID;
			for (j = 1; < arrayGetSize(gGarrisonableBuilding))
			{
				buildingID = arrayGetInt(gGarrisonableBuilding, j);
				if (getDistance(location, kbUnitGetPosition(buildingID)) <
					getDistance(location, kbUnitGetPosition(closestBuildingID)))
					closestBuildingID = buildingID;
			}
			aiTaskUnitWork(unitID, closestBuildingID);
			if (xsIsRuleEnabled("ungarrisonVillagers") == false)
				xsEnableRule("ungarrisonVillagers");
		}
	}
}

rule ungarrisonVillagers
inactive
minInterval 5
{
	if (gGarrisonableBuilding < 0)
		return;

	int buildingID = -1;
	int enemyCount = -1;
	int allyCount = -1;
	vector location = cInvalidVector;
	bool disable = true;
	for (i = 0; < arrayGetSize(gGarrisonableBuilding))
	{
		buildingID = arrayGetInt(gGarrisonableBuilding, i);
		location = kbUnitGetPosition(buildingID);
		enemyCount = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia,
			cUnitStateAlive, location, 45.0);
		allyCount = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationAlly,
			cUnitStateAlive, location, 45.0);
		if (enemyCount > 4)
		{
			continue;
		}
		aiTaskUnitEject(buildingID, location + gDirection_DOWN * 5.0);
	}

	// if (disable == true)
	// 	xsDisableSelf();
}

//==============================================================================
// addMillBuildPlan
//==============================================================================
int addMillBuildPlan(void)
{
	if (gTimeToFarm == false)
		gTimeToFarm = true;

	// We are already maxed out.
	if (kbUnitCount(cMyID, gFarmUnit, cUnitStateABQ) + arrayGetSize(gMillTypePlans) >=
		kbGetBuildLimit(cMyID, gFarmUnit) && kbGetBuildLimit(cMyID, gFarmUnit) > 0)
		return(-1);

	int buildPlanID = createBuildPlan(gFarmUnit, 1, 70, gHomeBase + gDirection_DOWN * 40.0);

	aiPlanSetDesiredResourcePriority(buildPlanID, 60); // above average but below villager production (indian villagers cost wood)

	return (buildPlanID);
}

//==============================================================================
// addPlantationBuildPlan
//==============================================================================
int addPlantationBuildPlan(void)
{
	if (gTimeForPlantations == false)
		gTimeForPlantations = true;

	// We are already maxed out.
	if (kbUnitCount(cMyID, gPlantationUnit, cUnitStateABQ) + arrayGetSize(gPlantationTypePlans) >=
		kbGetBuildLimit(cMyID, gPlantationUnit) && kbGetBuildLimit(cMyID, gPlantationUnit) > 0)
		return(-1);

	int buildPlanID = createBuildPlan(gPlantationUnit, 1, 70, gHomeBase + gDirection_DOWN * 40.0);
	aiPlanSetDesiredResourcePriority(buildPlanID, 60); // above average but below villager production (indian villagers cost wood)

	return (buildPlanID);
}

//==============================================================================
// tacticFarmMonitor
//==============================================================================
rule tacticFarmMonitor
inactive
group tcComplete
minInterval 10
{
	if (civIsAsian() == false && civIsAfrican() == false && cMyCiv != cCivDEMexicans)
	{
		xsDisableSelf();
		return;
	}

	static int paddyQueryID = -1;
	if (paddyQueryID < 0)
	{
		paddyQueryID = kbUnitQueryCreate("paddyGetUnitQuery");
		kbUnitQuerySetIgnoreKnockedOutUnits(paddyQueryID, true);
	}

	if (paddyQueryID != -1)
	{
		kbUnitQuerySetPlayerRelation(paddyQueryID, -1);
		kbUnitQuerySetPlayerID(paddyQueryID, cMyID);
		kbUnitQuerySetUnitType(paddyQueryID, gFarmUnit);
		kbUnitQuerySetState(paddyQueryID, cUnitStateAlive);
	}
	else
		return;

	kbUnitQueryResetResults(paddyQueryID);
	int numberFound = kbUnitQueryExecute(paddyQueryID);
	// Calculate a crude estimate.
	int numberFoodWanted = getRoundedNumber(aiGetResourcePercentage(cResourceFood) * numberFound);
	int numberGoldWanted = numberFound - numberFoodWanted;
	int numberOnFood = 0;
	int numberOnGold = 0;
	int unitID = -1;
	int index = 0;

	for (i = 0; < numberFound)
	{
		unitID = kbUnitQueryGetResult(paddyQueryID, i);
		if (aiUnitGetTactic(unitID) == gFarmFoodTactic)
			numberOnFood++;
		else
			numberOnGold++;
	}
	while (numberOnGold < numberGoldWanted)
	{
		if (index >= numberFound)
			break;	// ensure no infinite loop
		unitID = kbUnitQueryGetResult(paddyQueryID, index);
		if (aiUnitGetTactic(unitID) == gFarmFoodTactic)
		{
			aiUnitSetTactic(unitID, gFarmGoldTactic);
			numberOnFood--;
			numberOnGold++;
		}
		index++;
	}
	index = 0;
	while (numberOnFood < numberFoodWanted)
	{
		if (index >= numberFound)
			break;	// ensure no infinite loop
		unitID = kbUnitQueryGetResult(paddyQueryID, index);
		if (aiUnitGetTactic(unitID) == gFarmGoldTactic)
		{
			aiUnitSetTactic(unitID, gFarmFoodTactic);
			numberOnGold--;
			numberOnFood++;
		}
		index++;
	}
}

//==============================================================================
// rule econMasterRule
/*
	This rule calls the updateResourceDistribution() function on a regular basis.
*/
//==============================================================================
rule econMasterRule
inactive
group postStartup
minInterval 20
{
	updateResourceDistribution();

	int limit = kbGetBuildLimit(cMyID, gEconUnit);
	if (kbGetAge() == cAge1 && agingUp() == false)
	{
		aiPlanSetVariableInt(gSettlerMaintainPlan, cTrainPlanNumberToMaintain, 0, 16);
	}
	else
	{
		// Update regularly as the limit can change due to various factors.
		aiPlanSetVariableInt(gSettlerMaintainPlan, cTrainPlanNumberToMaintain, 0, limit);
	}

	// Account for Architects that may be acquired outside of Italians.
	// (Not sure if possible yet).
	if (xsIsRuleEnabled("architectManager") == false)
	{
		if (kbUnitCount(cMyID, cUnitTypedeArchitect, cUnitStateABQ) > 0)
			xsEnableRule("architectManager");
	}
}

rule herdMonitor
inactive
minInterval 15
{
	// Activated when a livestock pen is being built.  Wait for completion, and then
	// move the herd plan to the livestock pen.
	if (civIsNative() == true)
	{
		if (kbUnitCount(cMyID, cUnitTypeFarm, cUnitStateAlive) > 0)
		{
			aiPlanSetVariableInt(gHerdPlanID, cHerdPlanBuildingTypeID, 0, cUnitTypeFarm);
			aiPlanSetVariableBool(gHerdPlanID, cHerdPlanUseMultipleBuildings, 0, true);
			return;
		}
	}
	else if (cMyCiv == cCivDEMexicans)
	{
		if (kbUnitCount(cMyID, cUnitTypedeHacienda, cUnitStateAlive) > 0)
		{
			aiPlanSetVariableInt(gHerdPlanID, cHerdPlanBuildingTypeID, 0, cUnitTypedeHacienda);
			aiPlanSetVariableBool(gHerdPlanID, cHerdPlanUseMultipleBuildings, 0, true);
			return;
		}
	}
	else if (cMyCiv == cCivJapanese)
	{
		if (kbUnitCount(cMyID, cUnitTypeAbstractShrine, cUnitStateAlive) > 0)
		{
			aiPlanSetVariableInt(gHerdPlanID, cHerdPlanBuildingTypeID, 0, cUnitTypeAbstractShrine);
			aiPlanSetVariableBool(gHerdPlanID, cHerdPlanUseMultipleBuildings, 0, true);
			return;
		}
	}
	else
	{
		if (kbUnitCount(cMyID, gLivestockPenUnit, cUnitStateAlive) > 0)
		{
			aiPlanSetVariableInt(gHerdPlanID, cHerdPlanBuildingTypeID, 0, gLivestockPenUnit);
			aiPlanSetVariableBool(gHerdPlanID, cHerdPlanUseMultipleBuildings, 0, true);
			return;
		}
	}

	// Gather at TC as fallback.
	static int tcID = -1;
	if (tcID < 0)
	{
		getUnit(cUnitTypeAgeUpBuilding);
	}

	if (kbUnitGetHealth(tcID) < 0.01)
	{
		tcID = getUnit(cUnitTypeAgeUpBuilding);
	}

	if (tcID >= 0)
	{
		aiPlanSetVariableInt(gHerdPlanID, cHerdPlanBuildingTypeID, 0, kbUnitGetProtoUnitID(tcID));
		if (aiPlanGetVariableInt(gHerdPlanID, cHerdPlanBuildingID, 0) != tcID)
			aiPlanSetVariableInt(gHerdPlanID, cHerdPlanBuildingID, 0, tcID);
		aiPlanSetVariableBool(gHerdPlanID, cHerdPlanUseMultipleBuildings, 0, false);
	}
}

rule maintainCreeCoureurs
inactive
minInterval 30
{
	static int creePlan = -1;
	int limit = 0;

	// Check build limit
	limit = kbGetBuildLimit(cMyID, cUnitTypeCoureurCree);

	if (kbUnitCount(cMyID, cUnitTypeTradingPost, cUnitStateAlive) < 1)
		limit = 0;

	// Create/update maintain plan
	if ((creePlan < 0) && (limit >= 1))
	{
		creePlan = createSimpleMaintainPlan(cUnitTypeCoureurCree, limit, true, kbBaseGetMainID(cMyID), 1);
	}
	else
	{
		aiPlanSetVariableInt(creePlan, cTrainPlanNumberToMaintain, 0, limit);
	}
}

rule maintainBerberNomads
inactive
minInterval 30
{
	static int nomadPlan = -1;
	int limit = 0;

	if (kbUnitCount(0, cUnitTypedeSocketBerbers, cUnitStateAny) == 0)
		return;

	// Check build limit
	limit = kbGetBuildLimit(cMyID, cUnitTypedeNatNomad);

	if (kbUnitCount(cMyID, cUnitTypeTradingPost, cUnitStateAlive) < 1)
		limit = 0;

	// Create/update maintain plan
	if ((nomadPlan < 0) && (limit >= 1))
	{
		nomadPlan = createSimpleMaintainPlan(cUnitTypedeNatNomad, limit, true, kbBaseGetMainID(cMyID), 1);
	}
	else
	{
		aiPlanSetVariableInt(nomadPlan, cUnitTypedeNatNomad, 0, limit);
	}
}

//==============================================================================
// monitorFeeding
// This rule gets activated by the commHandler when a player requests we feed him resources.
// We can only feed resources to one player at a time, so if 2 humans ask us to feed 
// we will only feed the last player who requested it.
// This monitor doesn't send any AI chats because they can get quite spammy in here.
//==============================================================================
rule monitorFeeding
inactive
minInterval 60
{
	// Ignore already eliminated players and reset the global.
	if (kbHasPlayerLost(gFeedGoldTo) == true)
	{
		gFeedGoldTo = 0;
	}
	if (kbHasPlayerLost(gFeedWoodTo) == true)
	{
		gFeedWoodTo = 0;
	}
	if (kbHasPlayerLost(gFeedFoodTo) == true)
	{
		gFeedFoodTo = 0;
	}
	
	// We have no active feeds anymore so disable.
	if ((gFeedGoldTo < 1) && (gFeedWoodTo < 1) && (gFeedFoodTo < 1))
	{
		xsDisableSelf();
	}

	if (gFeedGoldTo > 0)
	{
		if (handleTributeRequest(cResourceGold, gFeedGoldTo) == false)
		{
			debugEconomy("We don't have enough spare Gold to feed player: " + gFeedGoldTo);
		}
	}
	if (gFeedWoodTo > 0)
	{
		if (handleTributeRequest(cResourceWood, gFeedWoodTo) == false)
		{
			debugEconomy("We don't have enough spare Wood to feed player: " + gFeedWoodTo);
		}
	}
	if (gFeedFoodTo > 0)
	{
		if (handleTributeRequest(cResourceFood, gFeedFoodTo) == false)
		{
			debugEconomy("We don't have enough spare Food to feed player: " + gFeedFoodTo);
		}
	}
}

//==============================================================================
/*	
	Resource Trickle Monitors
*/
//==============================================================================
rule tradeRouteTacticMonitor
inactive
minInterval 60
{
	int numberTradingPostsOnRoute = 0;
	int tradingPostID = -1;
	int tradingPostTactic = -1;
	const int crateTypeInfluence = 3;

	for (routeIndex = 0; < gNumberTradeRoutes)
	{
		numberTradingPostsOnRoute = kbTradeRouteGetNumberTradingPosts(routeIndex);
		for (tradingPostIndex = 0; < numberTradingPostsOnRoute)
		{
			tradingPostID = kbTradeRouteGetTradingPostID(routeIndex, tradingPostIndex);
			if (kbUnitGetPlayerID(tradingPostID) == cMyID)
			{
				// Check if the TR is capable of generating resources.
				if ((kbBuildingTechGetStatus(xsArrayGetInt(gTradeRouteUpgrades, cTradeRouteFirstUpgrade +
					(routeIndex * 2)), tradingPostID) == cTechStatusActive) ||
					(xsArrayGetInt(gTradeRouteIndexAndType, routeIndex) == cTradeRouteCapturableAfrica) ||
					(xsArrayGetInt(gTradeRouteIndexAndType, routeIndex) == cTradeRouteCapturableAsia))
				{
					if (tradingPostTactic == -1) // If we didn't calculate a tactic yet do so, this carries over for all routes/tps.
					{
						// Get which resource type should be generated.
						tradingPostTactic = cResourceWood;
						// 20% Chance for African civs to just set it to Influence when we're below 500 Influence.
						// Don't do this when we absolutely need wood though.
						if (civIsAfrican() == true)
						{
							if ((aiRandInt(5) < 1) &&
								(kbResourceGet(cResourceInfluence) < 500)) 
							{
								tradingPostTactic = crateTypeInfluence;
							}
						}
						debugEconomy("Setting all Trading Posts to collect: " +
							kbGetProtoUnitName(xsArrayGetInt(gTradeRouteCrates, tradingPostTactic + (routeIndex * 4))));
						aiSetTradingPostUnitType(
							tradingPostID, xsArrayGetInt(gTradeRouteCrates, tradingPostTactic + (routeIndex * 4)));
					}
					else
					{
						aiSetTradingPostUnitType(
							tradingPostID, xsArrayGetInt(gTradeRouteCrates, tradingPostTactic + (routeIndex * 4)));
					}
				}
				else
				{
					break; // This route doesn't have the first upgrade active yet so continue on to the next route.
				}
			}
		}
	}
}

void factoryTacticMonitor()
{
	int factoryQueryID = createSimpleUnitQuery(cUnitTypeFactory, cMyID, cUnitStateAlive);
	kbUnitQuerySetIgnoreKnockedOutUnits(factoryQueryID, true);
	int numberFound = kbUnitQueryExecute(factoryQueryID);
	if (numberFound <= 0)
		return;

	if (numberFound == 1)
	{
		researchSimpleTech(cTechFactoryWaterPower, -1, cUnitTypeFactory, 99);
		aiUnitSetTactic(kbUnitQueryGetResult(factoryQueryID, 0), cTacticWood);
		return;
	}

	if (numberFound == 2)
	{
		researchSimpleTech(cTechFactoryMassProduction, -1, cUnitTypeFactory, 99);
		switch (cMyCiv)
		{
			case cCivBritish:
			{
				researchSimpleTech(cTechImperialRocket, -1, cUnitTypeFactory, 50);
				break;
			}
			case cCivOttomans:
			{
				researchSimpleTech(cTechImperialBombard, -1, cUnitTypeFactory, 50);
				break;
			}
			default:
			{
				researchSimpleTech(cTechImperialCannon, -1, cUnitTypeFactory, 50);
				break;
			}
		}
		aiUnitSetTactic(kbUnitQueryGetResult(factoryQueryID, 1), cTacticCannon);
		return;
	}

	if (numberFound == 3)
	{
		aiUnitSetTactic(kbUnitQueryGetResult(factoryQueryID, 2), cTacticWood);
	}
}

rule shrineTacticMonitor
inactive
minInterval 30
{
	if (cMyCiv != cCivJapanese)
	{
		xsDisableSelf();
		return;
	}

	int shrineID = getUnit(cUnitTypeypShrineJapanese, cMyID, cUnitStateAlive);
	if (shrineID != -1 && kbGetAge() >= cAge2)
	{
		aiUnitSetTactic(shrineID, cTacticShrineWood);
		xsDisableSelf();
	}
}

rule porcelainTowerTacticMonitor
inactive
mininterval 60
{
	// Check for the Porcelain Tower, if we don't find one we've lost it and we can disable this Rule.
	int porcelainTowerID = getUnit(gPorcelainTowerPUID);
	if (porcelainTowerID < 0)
	{
		xsDisableSelf();
		return;
	}

	int porcelainTowerTactic = cTacticWonderWood;
	/* switch (getMostNeededResource())
	{
	case cResourceGold:
	{
		porcelainTowerTactic = cTacticWonderCoin;
		break;
	}
	case cResourceWood:
	{
		porcelainTowerTactic = cTacticWonderWood;
		break;
	}
	default: // Food.
	{
		porcelainTowerTactic = cTacticWonderFood;
		break;
	}
	} */

	debugEconomy("Setting our Porcelain Tower to collect: " + porcelainTowerTactic);
	aiUnitSetTactic(porcelainTowerID, porcelainTowerTactic);
	xsDisableSelf();
}

rule sacredFieldMonitor
inactive
minInterval 60
{

	static int cowPlan = -1;
	int numHerdables = 0;
	int numCows = 0;


	// Build a sacred field if there is none and we're either in age2, have herdables or excess wood
	if ((kbUnitCount(cMyID, cUnitTypeypSacredField, cUnitStateAlive) < 1) &&
		((kbGetAge() >= cAge2) || (kbUnitCount(cMyID, cUnitTypeHerdable, cUnitStateAlive) + kbUnitCount(cMyID, cUnitTypeypSacredCow, cUnitStateAlive) > 0)) ||
		(kbResourceGet(cResourceWood) > 650))
	{	// Make sure we're not at the limit yet or are already trying to build one
		if ((kbGetBuildLimit(cMyID, cUnitTypeypSacredField) > kbUnitCount(cMyID, cUnitTypeypSacredField, cUnitStateAlive)) &&
			(aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeypSacredField) < 0))
		{
			createBuildPlan(cUnitTypeypSacredField, 1, 50, gHomeBase);
			return;
		}
	}

	// Quit if there is no sacred field around or we're in age1 without excess food
	if ((kbUnitCount(cMyID, cUnitTypeypSacredField, cUnitStateAlive) < 1) &&
		 (kbGetAge() == cAge1) &&
		 (kbResourceGet(cResourceFood) < 925))
	{
		return;
	}

	// Check number of captured herdables, add sacred cows as necessary to bring total number to 10
	numHerdables = kbUnitCount(cMyID, cUnitTypeHerdable, cUnitStateAlive) - kbUnitCount(cMyID, cUnitTypeypSacredCow, cUnitStateAlive);
	if (numHerdables < 0)
		numHerdables = 0;
	numCows = 10 - numHerdables;
	if (numCows > 0)
	{
		// Create/update maintain plan
		if (cowPlan < 0)
		{
			cowPlan = createSimpleMaintainPlan(cUnitTypeypSacredCow, numCows, true, kbBaseGetMainID(cMyID), 1);
		}
		else
		{
			aiPlanSetVariableInt(cowPlan, cTrainPlanNumberToMaintain, 0, numCows);
		}
	}

}

//==============================================================================
// Livestock Market Functions
//==============================================================================
rule maintainLivestockAfricans
inactive
minInterval 45
{
	static int cattleTypeID = -1;
	if (cattleTypeID < 0)
	{
		if (cMyCiv == cCivDEEthiopians)
			cattleTypeID = cUnitTypedeZebuCattle;
		else if (cMyCiv == cCivDEHausa)
			cattleTypeID = cUnitTypedeSangaCattle;
	}
	static int uniqueCattleMaintainPlan = -1;
	// If we start this rule in cAge3, then that is 5 * 2 = 10, 15 for cAge4, 20 for cAge5
	// (which is the build limit).
	int numberUniqueCattleToMaintain = 5 * kbGetAge();
	if (uniqueCattleMaintainPlan < 0)
	{
		uniqueCattleMaintainPlan = createSimpleMaintainPlan(cattleTypeID,
			numberUniqueCattleToMaintain, true, kbBaseGetMainID(cMyID), 1);
	}
	else
	{
		aiPlanSetVariableInt(uniqueCattleMaintainPlan, cTrainPlanNumberToMaintain,
			0, numberUniqueCattleToMaintain);
	}

	if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypedeLivestockMarket) < 0)
	{
		int numHerdables = kbUnitCount(cMyID, cUnitTypeHerdable, cUnitStateAlive);
		int herdableCapacity = 10 * kbUnitCount(cMyID, cUnitTypedeLivestockMarket, cUnitStateABQ);
		if (numHerdables > herdableCapacity)
			createBuildPlan(cUnitTypedeLivestockMarket, 1, 50, gHomeBase + gDirection_DOWN * 20.0);
	}
}

int getBestResourceRateLivestockMarket(void)
{
	int retVal = -1;
	if (aiLivestockGetExchangeRate(cResourceGold) > aiLivestockGetExchangeRate(cResourceWood))
		retVal = cResourceGold;
	else
		retVal = cResourceWood;
	return(retVal);
}

rule livestockMarketSellMonitor
inactive
minInterval 30
{
	if (kbUnitCount(cMyID, cUnitTypedeLivestockMarket, cUnitStateAlive) == 0)
		return;

	static int herdableQuery = -1;
	static bool sellEarlyForWood = true;
	static bool wait = true;
	static int count = 0;

	if (herdableQuery < 0)
	{
		xsSetRuleMinIntervalSelf(3); // Will be updated once we sell for starting wood.
		herdableQuery = kbUnitQueryCreate("Herdable Query for Market Selling");
		kbUnitQuerySetPlayerID(herdableQuery, cMyID);
		kbUnitQuerySetUnitType(herdableQuery, cUnitTypeHerdable);
		kbUnitQuerySetState(herdableQuery, cUnitStateAlive);
		sellEarlyForWood = true;
	}

	kbUnitQueryResetResults(herdableQuery);
	int herdableCount = kbUnitQueryExecute(herdableQuery);
	if (herdableCount <= 0)
		return;

	int herdableID = -1;
	int bestHerdableID = -1;
	float amount = 0.0;
	float bestAmount = 0.0;
	int sellingResource = getBestResourceRateLivestockMarket();
	if (sellEarlyForWood == true)
		sellingResource = cResourceWood;
	float maxRate = aiLivestockGetMaximumRate();

	if (sellEarlyForWood == false)
	{
		// If we have cattle sitting at max capacity, sell if rate >= 50%.
		for (i = 0; < herdableCount)
		{
			if (aiLivestockGetExchangeRate(sellingResource) < maxRate * 0.5)
				break;
			herdableID = kbUnitQueryGetResult(herdableQuery, i);
			amount = kbUnitGetResourceAmount(herdableID, cResourceFood);
			if (amount >= kbUnitGetCarryCapacity(herdableID, cResourceFood))
			{
				aiLivestockSell(sellingResource, herdableID);
				// Update because the rates changed.
				sellingResource = getBestResourceRateLivestockMarket();
			}
		}

		if (aiLivestockGetExchangeRate(sellingResource) < maxRate)
			return;
	}

	for (i = 0; < herdableCount)
	{
		herdableID = kbUnitQueryGetResult(herdableQuery, i);
		amount = kbUnitGetResourceAmount(herdableID, cResourceFood);
		if (bestAmount < amount)
		{
			bestHerdableID = herdableID;
			bestAmount = amount;
		}
	}

	// If we are here we have reached maximum exchange rate,
	// so sell a herdable if one is at least 80% fattened.
	if (sellEarlyForWood == false)
	{
		if (bestAmount < 0.8 * kbUnitGetCarryCapacity(bestHerdableID, cResourceFood))
			return;
	}
	else
	{
		if ((aiLivestockGetExchangeRate(cResourceWood) * bestAmount) <
			kbUnitCostPerResource(gHouseUnit, cResourceWood))
		{
			return;
		}
	}

	aiLivestockSell(sellingResource, bestHerdableID);

	if (sellEarlyForWood == true)
	{
		xsSetRuleMinIntervalSelf(30);
		// Ensure we can get a house up ASAP.
		sellEarlyForWood = false;
		int planID = createBuildPlan(gHouseUnit, 1, 99, gHomeBase);
		aiPlanSetDesiredResourcePriority(planID, 99);
		arrayPushInt(gHouseBuildPlans, planID);
		xsEnableRule("houseMonitor");
	}
}
