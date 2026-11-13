//==============================================================================
/* aiMilitary.xs

	This file is intended for any military related stuffs, not limited to army
	training, researching upgrades and combat handling.

*/
//==============================================================================

//==============================================================================
// mostHatedEnemy
// Determine who we should attack, checking cvPlayerToAttack too
//==============================================================================
rule mostHatedEnemy
minInterval 60
inactive
{
	if (cvPlayerToAttack > 0)
	{
		debugMilitary("**** cv Changing most hated Player from " + aiGetMostHatedPlayerID() + " to " + cvPlayerToAttack);
		aiSetMostHatedPlayerID(cvPlayerToAttack);
		if (gLandUnitPicker >= 0)
		{
			kbUnitPickSetEnemyPlayerID(gLandUnitPicker, cvPlayerToAttack); // Update the unit picker.
		}
		xsDisableSelf(); // Most likely the cvPlayerToAttack will not be changed in the middle of the game so don't check again.
		return;
	}

	static bool treatyTargetingPerformed = false;
	int arrayIndex = 0;
	int arrayIndexOfSelectedEnemy = 0;
	gNumEnemies = 0;
	bool isTreatyActive = aiTreatyActive();
	
	if (isTreatyActive == true && treatyTargetingPerformed == false) // We only perform the targeting once during treaty.
	{
		// Add IDs of enemies to the array.
		for (i = 1; < cNumberPlayers)
		{
			if (kbGetPlayerTeam(i) != kbGetPlayerTeam(cMyID)) // Not on our team so must be an enemy.
			{
				if (kbHasPlayerLost(i) == false)
				{
					xsArraySetInt(gArrayEnemyPlayerIDs, arrayIndex, i);
					arrayIndex = arrayIndex +1;
					gNumEnemies = gNumEnemies + 1;
				}
			}
		}
		if (kbGetIsFFA()) // We pick a target that is adjacent to us in FFA.
		{
			if(gNumEnemies >= 3) // We only need to sort when we have more than 2 enemies, because if we only have 2 enemies we just chose either one anyway regardless of distance.
			{
				arraySortInt(gArrayEnemyPlayerIDs, 0, gNumEnemies, [](int playerA = 1, int playerB = 2) -> bool
				{
					return(xsArrayGetFloat(gStartingPosDistances, playerA) < xsArrayGetFloat(gStartingPosDistances, playerB));
				});
			}
			arrayIndexOfSelectedEnemy = gNumEnemies >= 2 ? aiRandInt(2) : 0;
		}
		else
		{
			arrayIndexOfSelectedEnemy = aiRandInt(gNumEnemies);
		}
		
		aiSetMostHatedPlayerID(xsArrayGetInt(gArrayEnemyPlayerIDs, arrayIndexOfSelectedEnemy));
		debugMilitary("*** Treaty targeting randomly selected Player " + xsArrayGetInt(gArrayEnemyPlayerIDs, arrayIndexOfSelectedEnemy) + " to be our most hated player");

		if (gLandUnitPicker >= 0)
		{
			kbUnitPickSetEnemyPlayerID(gLandUnitPicker, xsArrayGetInt(gArrayEnemyPlayerIDs, arrayIndexOfSelectedEnemy)); // Update the unit picker.
		}
		
		treatyTargetingPerformed = true;
		return;
	}
	
	if (isTreatyActive == false)
	{
		// Add IDs of enemies who are still alive to the array.
		for (i = 1; < cNumberPlayers)
		{
			if (kbIsPlayerEnemy(i)) 
			{
				if (kbHasPlayerLost(i) == false)
				{
					xsArraySetInt(gArrayEnemyPlayerIDs, arrayIndex, i);
					arrayIndex = arrayIndex +1;
					gNumEnemies = gNumEnemies + 1;
				}
			}
		}

		if (kbGetIsFFA()) // We pick a target that is adjacent to us in FFA.
		{
			if(gNumEnemies >= 3) // We only need to sort when we have more than 2 enemies, because if we only have 2 enemies we just chose either one anyway regardless of distance.
			{
				arraySortInt(gArrayEnemyPlayerIDs, 0, gNumEnemies, [](int playerA = 1, int playerB = 2) -> bool
				{
					return(xsArrayGetFloat(gStartingPosDistances, playerA) < xsArrayGetFloat(gStartingPosDistances, playerB));
				});
			}
			arrayIndexOfSelectedEnemy = gNumEnemies >= 2 ? aiRandInt(2) : 0;
		}
		else
		{
			arrayIndexOfSelectedEnemy = aiRandInt(gNumEnemies);
		}

		aiSetMostHatedPlayerID(xsArrayGetInt(gArrayEnemyPlayerIDs, arrayIndexOfSelectedEnemy));
		debugMilitary("*** Randomly selected Player " + xsArrayGetInt(gArrayEnemyPlayerIDs, arrayIndexOfSelectedEnemy) + " to be our most hated player");
		
		if (gLandUnitPicker >= 0)
		{
			kbUnitPickSetEnemyPlayerID(gLandUnitPicker, xsArrayGetInt(gArrayEnemyPlayerIDs, arrayIndexOfSelectedEnemy)); // Update the unit picker.
		}
	}
}

//==============================================================================
// addUnitsToMilitaryPlan
//==============================================================================
void addUnitsToMilitaryPlan(int planID = -1)
{
	//int numberLandMilitaryUnits = aiPlanGetNumberUnits(gLandReservePlan, cUnitTypeLogicalTypeLandMilitary);

	// TODO: don't always task the full army, leave some behind if the enemy is weak or we need more defense   
	if ((gRevolutionType & cRevolutionFinland) == 0)
	{
		aiPlanAddUnitType(planID, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);
		aiPlanAddUnitType(planID, cUnitTypeMinuteman, 0, 0, 0, true, true);
		aiPlanAddUnitType(planID, cUnitTypeypIrregular, 0, 0, 0, true, true);
		aiPlanAddUnitType(planID, cUnitTypeypPeasant, 0, 0, 0, true, true);
		aiPlanAddUnitType(planID, cUnitTypexpWarrior, 0, 0, 0, true, true);
		aiPlanAddUnitType(planID, cUnitTypedeSpearmanLevy, 0, 0, 0, true, true);
		aiPlanAddUnitType(planID, cUnitTypedeBowmanLevy, 0, 0, 0, true, true);
		aiPlanAddUnitType(planID, cUnitTypedeGunnerLevy, 0, 0, 0, true, true);
		return;
	}

	// For the finland revolution, keep some karelian jaegers around to sustain the economy
	int numberAvailableEconUnits = 0;
	int queryID = createSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive);
	int numberFound = kbUnitQueryExecute(queryID);

	aiPlanAddUnitType(planID, cUnitTypeLogicalTypeLandMilitary, 0, 0, 0);

	// Add each unit type individually
	for (i = 0; < numberFound)
	{
		int unitID = kbUnitQueryGetResult(queryID, i);
		int puid = kbUnitGetProtoUnitID(unitID);
		if (puid == gEconUnit)
		{
			int unitPlanType = aiPlanGetType(kbUnitGetPlanID(unitID));
			if (unitPlanType == cPlanGather || unitPlanType == cPlanBuild)
				numberAvailableEconUnits = numberAvailableEconUnits + 1;
			continue;
		}
		aiPlanAddUnitType(planID, puid, 0, 0, 200);
	}

	// Keep at least 30 karelian jaegers around or the equivalent wood amount
	float numberEconUnits = (0.0 - xsArrayGetFloat(gResourceNeeds, cResourceWood) - 3000.0) / 100.0;
	if (numberEconUnits < 0.0)
	{
		numberEconUnits = numberAvailableEconUnits + numberEconUnits;
		if (numberEconUnits < 0.0)
			numberEconUnits = 0.0;
	}
	else
	{
		numberEconUnits = numberAvailableEconUnits;
	}
	aiPlanAddUnitType(planID, gEconUnit, 0, numberEconUnits, numberEconUnits);
}


//==============================================================================
// updateMilitaryTrainPlanBuildings
//==============================================================================
// void updateMilitaryTrainPlanBuildings(int baseID = -1) {} TODO (James)


//==============================================================================
/*
	Military Manager

	Create maintain plans for military unit lines.  Control 'maintain' levels,
	buy upgrades.
*/
//==============================================================================
rule militaryManager
inactive
minInterval 28
{
	static bool firstRun = false; // Flag to indicate vars, plans are initialized
	static int unitsNotMaintained = -1;
	static int unitsNotMaintainedValue = -1;
	static int unitsNotMaintainedUpgrade = -1;
	if (firstRun == false)
	{
		// Need to initialize, if we're allowed to.
		firstRun = true;
		if (cvNumArmyUnitTypes >= 0)
			gNumArmyUnitTypes = cvNumArmyUnitTypes;
		else
			gNumArmyUnitTypes = 3;
		gLandUnitPicker = initUnitPicker("Land military units", gNumArmyUnitTypes, 1, 30, -1, -1, 1, true);
			aiSetMinArmySize(10);
			unitsNotMaintained = xsArrayCreateInt(3, -1, "Units not maintained");
			unitsNotMaintainedValue = xsArrayCreateFloat(3, -1, "Units not maintained value");
			unitsNotMaintainedUpgrade = xsArrayCreateInt(3, -1, "Units not maintained upgrade");
	}

	if (gLandUnitPicker != -1)
	{
		int age = getAgingUpAge();
		int targetPlayer = aiGetMostHatedPlayerID();

		setUnitPickerPreference(gLandUnitPicker);

		kbUnitPickSetMinimumPop(gLandUnitPicker, 1);
		kbUnitPickSetMaximumPop(gLandUnitPicker, aiGetMilitaryPop());

		if (cvNumArmyUnitTypes < 0)
		{
			if (age < cAge3)
				gNumArmyUnitTypes = 2;
			else
				gNumArmyUnitTypes = 3;
			kbUnitPickSetDesiredNumberUnitTypes(gLandUnitPicker, gNumArmyUnitTypes, 1, true);
		}
		setUnitPickerCommon(gLandUnitPicker);
		kbUnitPickRun(gLandUnitPicker, age);

		int numMilitaryBuildings = xsArrayGetSize(gMilitaryBuildings);
		int planID = -1;
		int upgradePlanID = -1;
		float totalFactor = 0.0;
		int baseID = kbBaseGetMainID(cMyID);
		vector gatherPoint = kbBaseGetMilitaryGatherPoint(cMyID, baseID);
		int puid = -1;
		int buildingPUID = -1;
		int trainBuildingPUID = -1;
		int numberToMaintain = 0;
		int popCount = 0;
		int upgradeTechID = -1;
		float totalValue = 0.0;

		for (i = 0; < gNumArmyUnitTypes)
			totalFactor = totalFactor + kbUnitPickGetResultFactor(gLandUnitPicker, i);

		for (i = 0; < gNumArmyUnitTypes)
		{
			puid = kbUnitPickGetResult(gLandUnitPicker, i);
			trainBuildingPUID = -1;
			numberToMaintain = 0;
			popCount = kbGetProtoUnitPopCount(puid);

			// update maintain plan.
			planID = xsArrayGetInt(gArmyUnitMaintainPlans, i);
			if (planID >= 0 && puid != aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0))
			{
				int otherPlanID = -1;

				for (j = i + 1; < gNumArmyUnitTypes)
				{
					otherPlanID = xsArrayGetInt(gArmyUnitMaintainPlans, j);
					if (otherPlanID >= 0 && puid == aiPlanGetVariableInt(otherPlanID, cTrainPlanUnitType, 0))
					{
						xsArraySetInt(gArmyUnitMaintainPlans, j, planID);
						break;
					}
					otherPlanID = -1;
				}
				
				if (otherPlanID < 0)
				{
					aiPlanDestroy(planID);
					planID = -1;
				}
				else
				{
					planID = otherPlanID;
					xsArraySetInt(gArmyUnitMaintainPlans, i, planID);
				}
			}

			if (planID < 0 && puid >= 0)
			{
				planID = aiPlanCreate("Land military " + kbGetUnitTypeName(puid) + " maintain", cPlanTrain);
				aiPlanSetMilitary(planID, true);
				// Unit type.
				aiPlanSetVariableInt(planID, cTrainPlanUnitType, 0, puid);
				aiPlanSetBaseID(planID, baseID);
				aiPlanSetVariableVector(planID, cTrainPlanGatherPoint, 0, gatherPoint);
				aiPlanSetActive(planID);
				xsArraySetInt(gArmyUnitMaintainPlans, i, planID);
				debugMilitary("*** Creating maintain plan for " + kbGetUnitTypeName(puid));
			}

			if (popCount > 0)
				numberToMaintain = (kbUnitPickGetResultFactor(gLandUnitPicker, i) / totalFactor) * aiGetMilitaryPop() / popCount;
			else
			{
				numberToMaintain =
					(kbUnitPickGetResultFactor(gLandUnitPicker, i) / totalFactor) * aiGetMilitaryPop() /
					(kbUnitCostPerResource(puid, cResourceFood) +
					 kbUnitCostPerResource(puid, cResourceWood) +
					 kbUnitCostPerResource(puid, cResourceGold));
			}
			aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, numberToMaintain);
			if (aiGetMilitaryPop() != 0)
			{
				aiPlanSetDesiredResourcePriority(planID, 50);
				switch (kbGetAge())
				{
					case cAge1:
					{
						break;
					}
					case cAge2:
					{
						if (getCurrentMilitaryPop() < 12)
							aiPlanSetDesiredResourcePriority(planID, 60);
						break;
					}
					case cAge3:
					{
						if (getCurrentMilitaryPop() < 30)
							aiPlanSetDesiredResourcePriority(planID, 60);
						break;
					}
					default:
					{
						if (getCurrentMilitaryPop() < 50)
							aiPlanSetDesiredResourcePriority(planID, 60);
						break;
					}
				}
			}
			
			for (j = 0; < numMilitaryBuildings)
			{
				buildingPUID = xsArrayGetInt(gMilitaryBuildings, j);
				if (kbProtoUnitCanTrain(buildingPUID, puid) == true)
				{
					trainBuildingPUID = buildingPUID;
					break;
				}
			}

			// Unit upgrades.
			if (trainBuildingPUID >= 0 && age >= cAge3)
			{
				upgradeTechID = kbTechTreeGetCheapestUnitUpgrade(puid, trainBuildingPUID);
				if (upgradeTechID >= 0)
				{
					upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, upgradeTechID);
					
					if (upgradePlanID < 0)
					{
						upgradePlanID = aiPlanCreate("Research "+kbGetTechName(upgradeTechID), cPlanResearch);
						aiPlanSetVariableInt(upgradePlanID, cResearchPlanTechID, 0, upgradeTechID);
						aiPlanSetVariableInt(upgradePlanID, cResearchPlanBuildingTypeID, 0, trainBuildingPUID);
						aiPlanSetActive(upgradePlanID);
						debugMilitary("*** Creating research plan for "+kbGetTechName(upgradeTechID));
					}
				
					aiPlanSetParentID(upgradePlanID, planID);
					
					totalValue = kbUnitCostPerResource(puid, cResourceFood)
						+ kbUnitCostPerResource(puid, cResourceWood)
						+ kbUnitCostPerResource(puid, cResourceGold);
					totalValue = totalValue * kbUnitCount(cMyID, puid, cUnitStateABQ);

					aiPlanSetDesiredResourcePriority(upgradePlanID, 55);
				}
			}
			xsArraySetInt(gArmyUnitBuildings, i, trainBuildingPUID);
		}

		// Also research upgrades for units not maintained.
		if (cDifficultyCurrent >= cDifficultyModerate && age >= cAge3)
		{
			// Remove any units in the unit picker.
			for (i = 0; < 3)
			{
				puid = xsArrayGetInt(unitsNotMaintained, i);
				if (puid < 0)
					continue;
				for (j = 0; < gNumArmyUnitTypes)
				{
					if (puid == kbUnitPickGetResult(gLandUnitPicker, j))
					{
						xsArraySetInt(unitsNotMaintained, i, -1);
						upgradePlanID = xsArrayGetInt(unitsNotMaintainedUpgrade, i);
						if (upgradePlanID >= 0)
						{
							if (aiPlanGetParentID(upgradePlanID) < 0)
								aiPlanDestroy(upgradePlanID);
							xsArraySetInt(unitsNotMaintainedUpgrade, i, -1);
						}
						puid = -1;
						break;
					}
				}
				if (puid >= 0)
				{
					totalValue = kbUnitCostPerResource(puid, cResourceFood)
						+ kbUnitCostPerResource(puid, cResourceWood)
						+ kbUnitCostPerResource(puid, cResourceGold);
					totalValue = totalValue * kbUnitCount(cMyID, puid, cUnitStateAlive);
					xsArraySetFloat(unitsNotMaintainedValue, i, totalValue);
				}
				else
				{
					xsArraySetFloat(unitsNotMaintainedValue, i, 0.0);
				}
			}

			int militaryQuery = createSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive);
			int numberFound = kbUnitQueryExecute(militaryQuery);
			int unitID = -1;
			int militaryPUID = -1;
			float lowestTotalValue = 0.0;
			int lowestTotalValueIndex = 0;

			// Query all units, pick unit types with the highest total value.
			for (i = 0; < numberFound)
			{
				unitID = kbUnitQueryGetResult(militaryQuery, i);
				puid = kbUnitGetProtoUnitID(unitID);
				
				// avoid unit types in the unit picker.
				for (j = 0; < gNumArmyUnitTypes)
				{
					if (puid == kbUnitPickGetResult(gLandUnitPicker, j))
					{
						puid = -1;
						break;
					}
				}
				if (puid < 0)
					break;

				// ignore unit types already in the array.
				for (j = 0; < 3)
				{
					if (puid == xsArrayGetInt(unitsNotMaintained, j))
					{
						puid = -1;
						break;
					}
				}
				if (puid < 0)
					break;

				// pick unit type in the array with the lowest value and replace it.
				lowestTotalValue = 99999.0;
				lowestTotalValueIndex = 0;

				for (j = 0; < 3)
				{
					militaryPUID = xsArrayGetInt(unitsNotMaintained, j);
					totalValue = xsArrayGetFloat(unitsNotMaintainedValue, j);
					if (militaryPUID < 0 || lowestTotalValue > totalValue)
					{
						lowestTotalValue = totalValue;
						lowestTotalValueIndex = j;
						break;
					}
				}

				totalValue = kbUnitCostPerResource(puid, cResourceFood)
					+ kbUnitCostPerResource(puid, cResourceWood)
					+ kbUnitCostPerResource(puid, cResourceGold);
				totalValue = totalValue * kbUnitCount(cMyID, puid, cUnitStateAlive);

				if (totalValue > lowestTotalValue)
				{
					xsArraySetInt(unitsNotMaintained, lowestTotalValueIndex, puid);
					xsArraySetFloat(unitsNotMaintainedValue, lowestTotalValueIndex, totalValue);
					upgradePlanID = xsArrayGetInt(unitsNotMaintainedUpgrade, lowestTotalValueIndex);
					if (upgradePlanID >= 0)
						aiPlanDestroy(upgradePlanID);
					xsArraySetInt(unitsNotMaintainedUpgrade, lowestTotalValueIndex, -1);
				}
			}
			
			// Research upgrades when available.
			for (i = 0; < 3)
			{
				puid = xsArrayGetInt(unitsNotMaintained, i);
				for (j = 0; < numMilitaryBuildings)
				{
					buildingPUID = xsArrayGetInt(gMilitaryBuildings, j);
					if (kbProtoUnitCanTrain(buildingPUID, puid) == true)
					{
						trainBuildingPUID = buildingPUID;
						break;
					}
				}
				if (trainBuildingPUID >= 0)
				{
					upgradeTechID = kbTechTreeGetCheapestUnitUpgrade(puid, trainBuildingPUID);
					if (upgradeTechID >= 0)
					{
						upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, upgradeTechID);

						if (upgradePlanID < 0)
						{
							upgradePlanID = aiPlanCreate("Research "+kbGetTechName(upgradeTechID), cPlanResearch);
							aiPlanSetVariableInt(upgradePlanID, cResearchPlanTechID, 0, upgradeTechID);
							aiPlanSetVariableInt(upgradePlanID, cResearchPlanBuildingTypeID, 0, trainBuildingPUID);
							aiPlanSetActive(upgradePlanID);
							debugMilitary("*** Creating research plan for "+kbGetTechName(upgradeTechID));               
						}

						totalValue = xsArrayGetFloat(unitsNotMaintainedValue, i);

						// below default priority if we do not have enough units.
						if (totalValue < 1000.0)
							aiPlanSetDesiredResourcePriority(upgradePlanID, 45 - (5 - totalValue / 200));
						else
							aiPlanSetDesiredResourcePriority(upgradePlanID, 50);
						xsArraySetInt(unitsNotMaintainedUpgrade, i, upgradePlanID);
					}
				}
			}
		}
		// TODO (James): Military production at forward base.
/* 		if (cDifficultyCurrent >= cDifficultyHard)
		{
			planID = aiPlanGetIDByTypeAndVariableType(cPlanAttack, cAttackPlanBaseAttackMode, cAttackPlanBaseAttackModeExplicit);
			if (planID >= 0 && aiPlanGetVariableBool(planID, cAttackPlanAllowMoreUnitsDuringAttack, 0) == true)
				baseID = gForwardBaseID;
			else
				baseID = -1;
		} */
	}
}


//==============================================================================
// delayAttackMonitor
// We're on cDifficultyEasy aka Standard difficulty.
// It means we can't attack until AFTER someone has attacked us, or until we've reached age 4.
// It can also be that the loader file has set gDelayAttacks to false for this difficulty directly.
//==============================================================================
rule delayAttackMonitor
inactive
minInterval 10
{
	if (gDelayAttacks == false ||
		kbGetAge() >= cAge4 ||
		gDefenseReflexBaseID == kbBaseGetMainID(cMyID))
	{
		xsEnableRule("mostHatedEnemy"); // Picks a target for us to attack.
		mostHatedEnemy(); // Instantly get a target so our managers have something to work with.
		xsEnableRule("attackManager"); // Land attacking / defending allies.
		if (gNavyMap == true)
		{
			xsEnableRule("waterAttack"); // Water attacking.
		}
		xsDisableSelf();
	}
}


//==============================================================================
// traceTransientLandCombatMission
// Records one ordinary attack or ally-defense mission without changing its
// targeting, reinforcement, retreat, or termination behavior.
//==============================================================================
bool landMissionUnitSampleArraysReady(void)
{
	return(
		(gTracedLandMissionUnitIDs >= 0) &&
		(gTracedLandMissionUnitOriginPlanIDs >= 0) &&
		(gPostLandMissionUnitIDs >= 0) &&
		(gPostLandMissionUnitOriginPlanIDs >= 0));
}


void clearTracedLandMissionUnitSamples(void)
{
	gTracedLandMissionUnitCount = 0;
	gTracedLandMissionUnitCacheCapped = false;
	gTracedLandMissionUnit0 = -1;
	gTracedLandMissionUnit1 = -1;
	if (landMissionUnitSampleArraysReady() == false)
	{
		return;
	}

	int sampleIndex = 0;
	for (sampleIndex = 0; sampleIndex < cLandMissionUnitSampleCapacity; sampleIndex++)
	{
		xsArraySetInt(gTracedLandMissionUnitIDs, sampleIndex, -1);
		xsArraySetInt(gTracedLandMissionUnitOriginPlanIDs, sampleIndex, -1);
	}
}


void clearPostLandMissionUnitSamples(void)
{
	gPostLandMissionUnitCount = 0;
	gPostLandMissionUnitCacheCapped = false;
	gPostLandMissionUnit0 = -1;
	gPostLandMissionUnit1 = -1;
	if (landMissionUnitSampleArraysReady() == false)
	{
		return;
	}

	int sampleIndex = 0;
	for (sampleIndex = 0; sampleIndex < cLandMissionUnitSampleCapacity; sampleIndex++)
	{
		xsArraySetInt(gPostLandMissionUnitIDs, sampleIndex, -1);
		xsArraySetInt(gPostLandMissionUnitOriginPlanIDs, sampleIndex, -1);
	}
}


bool addTracedLandMissionUnitSample(int unitID = -1, int originPlanID = -1)
{
	if ((unitID < 0) || (landMissionUnitSampleArraysReady() == false))
	{
		return(false);
	}

	int sampleIndex = 0;
	for (sampleIndex = 0; sampleIndex < gTracedLandMissionUnitCount; sampleIndex++)
	{
		if (xsArrayGetInt(gTracedLandMissionUnitIDs, sampleIndex) == unitID)
		{
			// Prefer the immediate child as the most specific live origin.
			if (originPlanID != gTracedLandMissionPlanID)
			{
				xsArraySetInt(gTracedLandMissionUnitOriginPlanIDs, sampleIndex,
					originPlanID);
			}
			return(true);
		}
	}

	if (gTracedLandMissionUnitCount >= cLandMissionUnitSampleCapacity)
	{
		gTracedLandMissionUnitCacheCapped = true;
		return(false);
	}

	xsArraySetInt(gTracedLandMissionUnitIDs, gTracedLandMissionUnitCount, unitID);
	xsArraySetInt(gTracedLandMissionUnitOriginPlanIDs, gTracedLandMissionUnitCount,
		originPlanID);
	gTracedLandMissionUnitCount++;
	if (gTracedLandMissionUnitCount == 1)
	{
		gTracedLandMissionUnit0 = unitID;
	}
	else if (gTracedLandMissionUnitCount == 2)
	{
		gTracedLandMissionUnit1 = unitID;
	}
	return(true);
}


bool addPostLandMissionUnitSample(int unitID = -1, int originPlanID = -1)
{
	if ((unitID < 0) || (landMissionUnitSampleArraysReady() == false))
	{
		return(false);
	}

	int sampleIndex = 0;
	for (sampleIndex = 0; sampleIndex < gPostLandMissionUnitCount; sampleIndex++)
	{
		if (xsArrayGetInt(gPostLandMissionUnitIDs, sampleIndex) == unitID)
		{
			xsArraySetInt(gPostLandMissionUnitOriginPlanIDs, sampleIndex, originPlanID);
			return(true);
		}
	}

	if (gPostLandMissionUnitCount >= cLandMissionUnitSampleCapacity)
	{
		gPostLandMissionUnitCacheCapped = true;
		return(false);
	}

	xsArraySetInt(gPostLandMissionUnitIDs, gPostLandMissionUnitCount, unitID);
	xsArraySetInt(gPostLandMissionUnitOriginPlanIDs, gPostLandMissionUnitCount,
		originPlanID);
	gPostLandMissionUnitCount++;
	if (gPostLandMissionUnitCount == 1)
	{
		gPostLandMissionUnit0 = unitID;
	}
	else if (gPostLandMissionUnitCount == 2)
	{
		gPostLandMissionUnit1 = unitID;
	}
	return(true);
}


void copyTracedLandMissionUnitSamplesToPost(void)
{
	clearPostLandMissionUnitSamples();
	if (landMissionUnitSampleArraysReady() == false)
	{
		return;
	}

	int sampleIndex = 0;
	int unitID = -1;
	int originPlanID = -1;
	for (sampleIndex = 0; sampleIndex < gTracedLandMissionUnitCount; sampleIndex++)
	{
		unitID = xsArrayGetInt(gTracedLandMissionUnitIDs, sampleIndex);
		originPlanID = xsArrayGetInt(gTracedLandMissionUnitOriginPlanIDs, sampleIndex);
		addPostLandMissionUnitSample(unitID, originPlanID);
	}
	gPostLandMissionUnitCacheCapped = gTracedLandMissionUnitCacheCapped;
}


void cacheTransientLandMissionState(int planID = -1)
{
	static bool sampleArrayFailureReported = false;
	int parentUnitCount = 0;
	int parentPrimaryCount = 0;
	int parentUnitIndex = 0;
	int activePlanCount = 0;
	int activeIndex = 0;
	int childPlanID = -1;
	int childUnitCount = 0;
	int childUnitIndex = 0;
	int unitID = -1;
	if ((planID < 0) || (planID != gTracedLandMissionPlanID) || (aiPlanGetState(planID) < 0))
	{
		return;
	}

	clearTracedLandMissionUnitSamples();
	if (landMissionUnitSampleArraysReady() == false)
	{
		if (sampleArrayFailureReported == false)
		{
			debugEvent("MIL-INVARIANT", "land mission sample arrays unavailable");
			sampleArrayFailureReported = true;
		}
		return;
	}

	parentUnitCount = aiPlanGetNumberUnits(planID, cUnitTypeUnit, true);
	parentPrimaryCount = parentUnitCount;
	activePlanCount = aiPlanGetActiveCount();
	if (parentPrimaryCount > cLandMissionParentUnitSampleLimit)
	{
		parentPrimaryCount = cLandMissionParentUnitSampleLimit;
	}

	// Reserve two slots for engine child-plan members when the parent is large.
	for (parentUnitIndex = 0; parentUnitIndex < parentPrimaryCount; parentUnitIndex++)
	{
		unitID = aiPlanGetUnitByIndex(planID, parentUnitIndex);
		addTracedLandMissionUnitSample(unitID, planID);
	}

	for (activeIndex = 0; activeIndex < activePlanCount; activeIndex++)
	{
		childPlanID = aiPlanGetIDByActiveIndex(activeIndex);
		if ((childPlanID < 0) || (aiPlanGetParentID(childPlanID) != planID))
		{
			continue;
		}
		childUnitCount = aiPlanGetNumberUnits(childPlanID, cUnitTypeUnit, true);
		for (childUnitIndex = 0; childUnitIndex < childUnitCount; childUnitIndex++)
		{
			unitID = aiPlanGetUnitByIndex(childPlanID, childUnitIndex);
			addTracedLandMissionUnitSample(unitID, childPlanID);
			if (gTracedLandMissionUnitCacheCapped == true)
			{
				break;
			}
		}
		if (gTracedLandMissionUnitCacheCapped == true)
		{
			break;
		}
	}

	// Use any slots not needed by children for additional parent members.
	for (parentUnitIndex = parentPrimaryCount;
		parentUnitIndex < parentUnitCount;
		parentUnitIndex++)
	{
		unitID = aiPlanGetUnitByIndex(planID, parentUnitIndex);
		addTracedLandMissionUnitSample(unitID, planID);
		if (gTracedLandMissionUnitCacheCapped == true)
		{
			break;
		}
	}
	gTracedLandMissionTargetPoint = aiPlanGetVariableVector(planID, cCombatPlanTargetPoint, 0);
	gTracedLandMissionGatherPoint = aiPlanGetVariableVector(planID, cCombatPlanGatherPoint, 0);
}


string classifyPostLandMissionUnit(int unitID = -1, int currentPlanID = -1, int parentPlanID = -1)
{
	if ((unitID < 0) || (kbUnitGetPlayerID(unitID) != cMyID))
	{
		return("gone");
	}
	if (currentPlanID < 0)
	{
		return("idle");
	}
	if ((currentPlanID == gLandDefendPlan0) || (parentPlanID == gLandDefendPlan0))
	{
		return("defend");
	}
	if ((currentPlanID == gLandReservePlan) || (parentPlanID == gLandReservePlan))
	{
		return("reserve");
	}
	if ((currentPlanID == gTracedLandMissionPlanID) || (parentPlanID == gTracedLandMissionPlanID))
	{
		return("new-mission");
	}
	return("other");
}


void tracePostLandMissionUnit(int unitID = -1, int originPlanID = -1)
{
	if (unitID < 0)
	{
		return;
	}

	int ownerID = kbUnitGetPlayerID(unitID);
	int currentPlanID = -1;
	int parentPlanID = -1;
	int actionID = -1;
	int targetID = -1;
	vector unitPosition = cInvalidVector;
	if (ownerID == cMyID)
	{
		currentPlanID = kbUnitGetPlanID(unitID);
		if (currentPlanID >= 0)
		{
			parentPlanID = aiPlanGetParentID(currentPlanID);
		}
		actionID = kbUnitGetActionType(unitID);
		targetID = kbUnitGetTargetUnitID(unitID);
		unitPosition = kbUnitGetPosition(unitID);
	}

	vector homeGatherPoint = kbBaseGetMilitaryGatherPoint(cMyID, kbBaseGetMainID(cMyID));
	float targetDistance = -1.0;
	float homeDistance = -1.0;
	if (unitPosition != cInvalidVector)
	{
		if (gPostLandMissionTargetPoint != cInvalidVector)
		{
			targetDistance = getDistance(unitPosition, gPostLandMissionTargetPoint);
		}
		if (homeGatherPoint != cInvalidVector)
		{
			homeDistance = getDistance(unitPosition, homeGatherPoint);
		}
	}

	debugEvent("MIL-PLAN", "phase=post-state id=" + gPostLandMissionPlanID + " src=" +
		gPostLandMissionSource + " u=" + unitID + " origin=" + originPlanID +
		" owner=" + ownerID + " plan=" + currentPlanID + " parent=" + parentPlanID + " class=" +
		classifyPostLandMissionUnit(unitID, currentPlanID, parentPlanID) + " action=" +
		actionID + " target=" + targetID);
	debugEvent("MIL-PLAN", "phase=post-pos id=" + gPostLandMissionPlanID + " u=" +
		unitID + " dT=" + targetDistance + " dH=" + homeDistance + " pos=" +
		unitPosition);
}


void startPostLandMissionFollow(int planID = -1, int source = -1, string reason = "terminal")
{
	if (planID < 0)
	{
		return;
	}

	int now = xsGetTime();
	if ((gPostLandMissionPlanID == planID) && (now <= gPostLandMissionUntilTime))
	{
		return;
	}
	if ((gPostLandMissionPlanID >= 0) && (now <= gPostLandMissionUntilTime))
	{
		debugEvent("MIL-INVARIANT", "post-follow busy old=" + gPostLandMissionPlanID +
			" dropped=" + planID);
		return;
	}

	int followedUnit0 = -1;
	int followedUnit1 = -1;
	int liveUnitCount = 0;
	int liveUnitIndex = 0;
	int liveUnitID = -1;
	vector targetPoint = cInvalidVector;
	vector gatherPoint = cInvalidVector;
	clearPostLandMissionUnitSamples();
	if (aiPlanGetState(planID) >= 0)
	{
		if (planID == gTracedLandMissionPlanID)
		{
			cacheTransientLandMissionState(planID);
			copyTracedLandMissionUnitSamplesToPost();
		}
		else
		{
			// A concurrently untraced live mission has no child cache, but retain a
			// bounded parent sample instead of dropping all unit evidence.
			liveUnitCount = aiPlanGetNumberUnits(planID, cUnitTypeUnit, true);
			for (liveUnitIndex = 0;
				liveUnitIndex < liveUnitCount;
				liveUnitIndex++)
			{
				liveUnitID = aiPlanGetUnitByIndex(planID, liveUnitIndex);
				addPostLandMissionUnitSample(liveUnitID, planID);
				if (gPostLandMissionUnitCacheCapped == true)
				{
					break;
				}
			}
		}
		targetPoint = aiPlanGetVariableVector(planID, cCombatPlanTargetPoint, 0);
		gatherPoint = aiPlanGetVariableVector(planID, cCombatPlanGatherPoint, 0);
	}
	else if (planID == gTracedLandMissionPlanID)
	{
		copyTracedLandMissionUnitSamplesToPost();
		targetPoint = gTracedLandMissionTargetPoint;
		gatherPoint = gTracedLandMissionGatherPoint;
	}
	followedUnit0 = gPostLandMissionUnit0;
	followedUnit1 = gPostLandMissionUnit1;

	gPostLandMissionPlanID = planID;
	gPostLandMissionSource = source;
	gPostLandMissionTargetPoint = targetPoint;
	gPostLandMissionGatherPoint = gatherPoint;
	gPostLandMissionUntilTime = now + 30000;
	gPostLandMissionNextSampleTime = now;
	debugEvent("MIL-PLAN", "phase=post-start id=" + planID + " src=" + source +
		" reason=" + reason + " samples=" + gPostLandMissionUnitCount + " capped=" +
		gPostLandMissionUnitCacheCapped + " u0=" + followedUnit0 + " u1=" + followedUnit1);
	xsEnableRule("postLandMissionFollowMonitor");
}


void traceTransientLandCombatMission(int planID = -1, string phase = "snapshot")
{
	int planState = aiPlanGetState(planID);
	if (planState < 0)
	{
		debugEvent("MIL-PLAN", "phase=" + phase + " id=" + planID + " state=" + planState + " terminal=1");
		return;
	}

	cacheTransientLandMissionState(planID);
	int missionSource = -1;
	if (planID == gTracedLandMissionPlanID)
	{
		missionSource = gTracedLandMissionSource;
	}
	int combatType = aiPlanGetVariableInt(planID, cCombatPlanCombatType, 0);
	int directUnits = aiPlanGetNumberUnits(planID, cUnitTypeLogicalTypeLandMilitary, false);
	int unitsWithLoans = aiPlanGetNumberUnits(planID, cUnitTypeLogicalTypeLandMilitary, true);
	int loanedUnits = unitsWithLoans - directUnits;
	int childCount = 0;
	int activePlanCount = aiPlanGetActiveCount();
	int childPlanID = -1;
	for (int activeIndex = 0; activeIndex < activePlanCount; activeIndex++)
	{
		childPlanID = aiPlanGetIDByActiveIndex(activeIndex);
		if (childPlanID >= 0 && aiPlanGetParentID(childPlanID) == planID)
		{
			childCount++;
			if (childCount <= 2)
			{
				debugEvent("MIL-PLAN", "phase=child id=" + planID + " child=" + childPlanID +
					" type=" + aiPlanGetType(childPlanID) + " state=" + aiPlanGetState(childPlanID) +
					" units=" + aiPlanGetNumberUnits(childPlanID, cUnitTypeUnit, true));
			}
		}
	}

	debugEvent("MIL-PLAN", "phase=" + phase + " id=" + planID + " src=" + missionSource +
		" state=" + planState + " active=" + aiPlanGetActive(planID) + " orphan=" +
		aiPlanGetOrphan(planID) + " parent=" + aiPlanGetParentID(planID) + " combat=" + combatType);
	debugEvent("MIL-PLAN", "phase=target id=" + planID + " mode=" +
		aiPlanGetVariableInt(planID, cCombatPlanTargetMode, 0) + " player=" +
		aiPlanGetVariableInt(planID, cCombatPlanTargetPlayerID, 0) + " base=" +
		aiPlanGetVariableInt(planID, cCombatPlanTargetBaseID, 0) + " done=" +
		aiPlanGetVariableInt(planID, cCombatPlanDoneMode, 0) + " retreat=" +
		aiPlanGetVariableInt(planID, cCombatPlanRetreatMode, 0));
	debugEvent("MIL-PLAN", "phase=units id=" + planID + " assigned=" + directUnits + " loans=" +
		loanedUnits + " need=" + aiPlanGetNumberNeededUnits(planID, cUnitTypeLogicalTypeLandMilitary) +
		" want=" + aiPlanGetNumberWantedUnits(planID, cUnitTypeLogicalTypeLandMilitary) + " max=" +
		aiPlanGetNumberMaxUnits(planID, cUnitTypeLogicalTypeLandMilitary) + " children=" + childCount);
	debugEvent("MIL-PLAN", "phase=cache id=" + planID + " samples=" +
		gTracedLandMissionUnitCount + " capped=" + gTracedLandMissionUnitCacheCapped);

	vector targetPoint = aiPlanGetVariableVector(planID, cCombatPlanTargetPoint, 0);
	vector gatherPoint = aiPlanGetVariableVector(planID, cCombatPlanGatherPoint, 0);
	debugEvent("MIL-PLAN", "phase=position id=" + planID + " target=" + targetPoint + " gather=" +
		gatherPoint + " initial=" + aiPlanGetInitialPosition(planID) + " planBase=" +
		aiPlanGetBaseID(planID) + " inCombat=" +
		aiPlanGetVariableBool(planID, cCombatPlanInCombat, 0));

	int unitCount = aiPlanGetNumberUnits(planID, cUnitTypeUnit, true);
	if (unitCount > 2)
	{
		unitCount = 2;
	}
	for (int unitIndex = 0; unitIndex < unitCount; unitIndex++)
	{
		int unitID = aiPlanGetUnitByIndex(planID, unitIndex);
		if (unitID < 0)
		{
			continue;
		}
		vector unitPosition = kbUnitGetPosition(unitID);
		debugEvent("MIL-PLAN", "phase=unit id=" + planID + " sample=" + unitIndex + " unit=" + unitID +
			" plan=" + kbUnitGetPlanID(unitID) + " action=" + kbUnitGetActionType(unitID) +
			" target=" + kbUnitGetTargetUnitID(unitID) + " pos=" + unitPosition +
			" gatherDist=" + getDistance(unitPosition, gatherPoint));
	}
}


void registerTransientLandCombatMission(int planID = -1, int source = -1)
{
	if (gBetterAIDebug < 1)
		return;
	if (planID < 0)
	{
		debugEvent("MIL-INVARIANT", "attempted to register invalid transient land mission " + planID);
		return;
	}
	if (gTracedLandMissionPlanID >= 0 && gTracedLandMissionPlanID != planID &&
		aiPlanGetState(gTracedLandMissionPlanID) >= 0)
	{
		debugEvent("MIL-INVARIANT", "replacing live traced mission old=" + gTracedLandMissionPlanID +
			" new=" + planID);
	}
	gTracedLandMissionPlanID = planID;
	gTracedLandMissionSource = source;
	gTracedLandMissionNextSnapshotTime = xsGetTime() + 15000;
	clearTracedLandMissionUnitSamples();
	gTracedLandMissionTargetPoint = cInvalidVector;
	gTracedLandMissionGatherPoint = cInvalidVector;
	aiPlanSetEventHandler(planID, cPlanEventStateChange, "transientLandMissionHandler");
	xsEnableRule("transientLandMissionMonitor");
	traceTransientLandCombatMission(planID, "create");
}


void traceTransientLandMissionCancellation(int planID = -1, string reason = "script")
{
	if (gBetterAIDebug < 1)
		return;
	if (planID >= 0 && aiPlanGetState(planID) >= 0)
	{
		int missionSource = -1;
		if (planID == gTracedLandMissionPlanID)
		{
			missionSource = gTracedLandMissionSource;
		}
		cacheTransientLandMissionState(planID);
		debugEvent("MIL-PLAN", "phase=cancel id=" + planID + " src=" +
			missionSource + " reason=" + reason + " parent=" + aiPlanGetParentID(planID));
		traceTransientLandCombatMission(planID, "cancel-snapshot");
		startPostLandMissionFollow(planID, missionSource, reason);
	}
}


void transientLandMissionHandler(int planID = -1)
{
	if (gBetterAIDebug < 1)
		return;
	int planState = aiPlanGetState(planID);
	int missionSource = -1;
	if (planID == gTracedLandMissionPlanID)
	{
		missionSource = gTracedLandMissionSource;
	}
	if (planState < 0)
	{
		debugEvent("MIL-PLAN", "phase=terminate id=" + planID + " src=" +
			missionSource + " state=" + planState);
		startPostLandMissionFollow(planID, missionSource, "engine-terminal");
		if (planID == gTracedLandMissionPlanID)
		{
			gTracedLandMissionPlanID = -1;
			gTracedLandMissionSource = -1;
			gTracedLandMissionNextSnapshotTime = -1;
			clearTracedLandMissionUnitSamples();
			gTracedLandMissionTargetPoint = cInvalidVector;
			gTracedLandMissionGatherPoint = cInvalidVector;
		}
		return;
	}
	cacheTransientLandMissionState(planID);
	debugEvent("MIL-PLAN", "phase=state-change id=" + planID + " src=" +
		missionSource + " state=" + planState + " active=" +
		aiPlanGetActive(planID) + " inCombat=" +
		aiPlanGetVariableBool(planID, cCombatPlanInCombat, 0));
	if (planID == gTracedLandMissionPlanID &&
		xsGetTime() >= gTracedLandMissionNextSnapshotTime)
	{
		traceTransientLandCombatMission(planID, "state-snapshot");
		gTracedLandMissionNextSnapshotTime = xsGetTime() + 15000;
	}
}


rule transientLandMissionMonitor
inactive
minInterval 5
{
	if (gBetterAIDebug < 1)
	{
		xsDisableSelf();
		return;
	}
	if (gTracedLandMissionPlanID < 0)
	{
		xsDisableSelf();
		return;
	}
	if (aiPlanGetState(gTracedLandMissionPlanID) < 0)
	{
		debugEvent("MIL-PLAN", "phase=monitor-terminal id=" + gTracedLandMissionPlanID +
			" src=" + gTracedLandMissionSource);
		startPostLandMissionFollow(gTracedLandMissionPlanID, gTracedLandMissionSource,
			"monitor-terminal");
		gTracedLandMissionPlanID = -1;
		gTracedLandMissionSource = -1;
		gTracedLandMissionNextSnapshotTime = -1;
		clearTracedLandMissionUnitSamples();
		gTracedLandMissionTargetPoint = cInvalidVector;
		gTracedLandMissionGatherPoint = cInvalidVector;
		xsDisableSelf();
		return;
	}
	cacheTransientLandMissionState(gTracedLandMissionPlanID);
	if (xsGetTime() >= gTracedLandMissionNextSnapshotTime)
	{
		traceTransientLandCombatMission(gTracedLandMissionPlanID, "heartbeat");
		gTracedLandMissionNextSnapshotTime = xsGetTime() + 15000;
	}
}


rule postLandMissionFollowMonitor
inactive
minInterval 2
{
	if (gBetterAIDebug < 1)
	{
		xsDisableSelf();
		return;
	}
	if (gPostLandMissionPlanID < 0)
	{
		xsDisableSelf();
		return;
	}

	int now = xsGetTime();
	int sampleIndex = 0;
	int unitID = -1;
	int originPlanID = -1;
	if (now < gPostLandMissionNextSampleTime)
	{
		return;
	}

	for (sampleIndex = 0; sampleIndex < gPostLandMissionUnitCount; sampleIndex++)
	{
		unitID = xsArrayGetInt(gPostLandMissionUnitIDs, sampleIndex);
		originPlanID = xsArrayGetInt(gPostLandMissionUnitOriginPlanIDs, sampleIndex);
		tracePostLandMissionUnit(unitID, originPlanID);
	}
	gPostLandMissionNextSampleTime = now + 10000;

	if (now >= gPostLandMissionUntilTime)
	{
		debugEvent("MIL-PLAN", "phase=post-end id=" + gPostLandMissionPlanID +
			" src=" + gPostLandMissionSource + " samples=" + gPostLandMissionUnitCount +
			" capped=" + gPostLandMissionUnitCacheCapped + " u0=" +
			gPostLandMissionUnit0 + " u1=" + gPostLandMissionUnit1);
		gPostLandMissionPlanID = -1;
		gPostLandMissionSource = -1;
		clearPostLandMissionUnitSamples();
		gPostLandMissionTargetPoint = cInvalidVector;
		gPostLandMissionGatherPoint = cInvalidVector;
		gPostLandMissionUntilTime = -1;
		gPostLandMissionNextSampleTime = -1;
		xsDisableSelf();
	}
}


//==============================================================================
// attackManager
// This rule analyzes the current situation in the game and decides if we should 
// attack an enemy OR defend an ally in need.
//==============================================================================
rule attackManager
inactive
minInterval 15
{
	int mainBaseID = kbBaseGetMainID(cMyID);
	static int currentPlayer = -1;
	static int currentBaseIndex = -1;
	static int targetBaseID = -1;
	static vector targetBaseLocation = cInvalidVector;
	static int targetPlayer = 2;
	static bool targetIsEnemy = true;
	static bool targetShouldAttack = false;
	static float targetAffordable = 0.0;
	static float targetBaseAssets = 0.0;
	static float targetDistancePenalty = 0.0;
	static float targetScore = 0.0;
	static float maxBaseAssets = 100.0;

	bool treatyBlocked = aiTreatyActive();
	bool attacksDisabled = (cvOkToAttack == false);
	bool mainBaseDefenseBlocked = (gDefenseReflexBaseID == mainBaseID);
	float ageUpPriority = -1.0;
	if (gAgeUpResearchPlan >= 0)
	{
		ageUpPriority = aiPlanGetActualResourcePriority(gAgeUpResearchPlan);
	}
	bool ageUpBlocked = (ageUpPriority >= 52.0);
	bool missionBlocked = isDefendingOrAttacking();

	// Don't attack under treaty or main base is under attack or we want to focus on aging up or if we already have an attack /
	// "real" defend plan.
	if (treatyBlocked == true || attacksDisabled == true || mainBaseDefenseBlocked == true ||
		ageUpBlocked == true || missionBlocked == true)
	{
		debugMilitary("Quiting attackManager early because we're not allowed to make a plan");
		debugMilitary("gDefenseReflexBaseID: " + gDefenseReflexBaseID + ", mainBaseID: " + mainBaseID);
		debugMilitary("gAgeUpResearchPlan prio: " + ageUpPriority);
		debugMilitary("isDefendingOrAttacking: " + missionBlocked);
		if (currentPlayer >= 0 || currentBaseIndex >= 0)
		{
			string interruptReason = "existing mission";
			if (treatyBlocked == true)
			{
				interruptReason = "treaty";
			}
			else if (attacksDisabled == true)
			{
				interruptReason = "attacks disabled";
			}
			else if (mainBaseDefenseBlocked == true)
			{
				interruptReason = "main-base defense reflex";
			}
			else if (ageUpBlocked == true)
			{
				interruptReason = "age-up priority";
			}
			debugEvent("MIL-SCAN", "interrupted: " + interruptReason);
		}

		currentPlayer = -1;
		currentBaseIndex = -1;
		targetBaseID = -1;
		targetBaseLocation = cInvalidVector;
		targetPlayer = 2;
		targetIsEnemy = true;
		targetShouldAttack = false;
		targetAffordable = 0.0;
		targetBaseAssets = 0.0;
		targetDistancePenalty = 0.0;
		targetScore = 0.0;
		maxBaseAssets = 100.0;
		xsSetRuleMinIntervalSelf(15);
		return;
	}

	static int baseQuery = -1;
	static int baseEnemyQuery = -1;
	static int tradingPostQuery = -1;
	bool defendingMonopoly = false;
	bool attackingMonopoly = false;
	bool defendingKOTH = false;
	bool attackingKOTH = false;
	int currentTime = xsGetTime();
	int numberUnits = 0;
	int numberFound = 0;
	int numberEnemyFound = 0;
	int numberBases = 0;
	int baseID = -1;
	vector mainBaseLocation = kbBaseGetLocation(cMyID, mainBaseID);
	int mainAreaGroup = kbAreaGroupGetIDByPosition(mainBaseLocation);
	int baseAreaGroup = -1;
	vector baseLocation = cInvalidVector;
	vector location = cInvalidVector;
	float baseDistance = 0.0;
	float armyPower = 0.0;
	float buildingPower = 0.0;
	float militaryPower = 0.0;
	float enemyMilitaryPower = 0.0;
	float affordable = 0.0;
	float baseAssets = 0.0;
	float distancePenalty = 0.0;
	float score = 0.0;
	bool isEnemy = false;
	bool isKOTH = false;
	bool isTradingPost = false;
	bool shouldAttack = false;
	int availableMilitaryPop = aiGetAvailableMilitaryPop();
	int unitID = -1;
	int puid = -1;
	float unitPower = 0.0;
	int planID = -1;
	int difficulty = cDifficultyCurrent;
	bool isItalianWars = (cRandomMapName == "euItalianWars");
	bool isNorthernWars = (cRandomMapName == "eugreatnorthernwar");
	int cityStateQuery = -1;
	int crateFlagQuery = -1;
	bool isCityState = false;
	int numberControlledCityStates = 0;
	int numberBasesProcessed = 0;

	if (baseQuery < 0)
	{
		baseQuery = kbUnitQueryCreate("attackBaseQuery");
		kbUnitQuerySetIgnoreKnockedOutUnits(baseQuery, true);

		baseEnemyQuery = kbUnitQueryCreate("attackBaseEnemyQuery");
		kbUnitQuerySetIgnoreKnockedOutUnits(baseEnemyQuery, true);

		tradingPostQuery = kbUnitQueryCreate("tradingPostQuery for Monopoly Targeting");
		kbUnitQuerySetIgnoreKnockedOutUnits(tradingPostQuery, true);
		kbUnitQuerySetPlayerRelation(tradingPostQuery, cPlayerRelationEnemyNotGaia);
		kbUnitQuerySetState(tradingPostQuery, cUnitStateAlive);
		kbUnitQuerySetPosition(tradingPostQuery, mainBaseLocation);
		kbUnitQuerySetUnitType(tradingPostQuery, cUnitTypeTradingPost);
		kbUnitQuerySetAscendingSort(tradingPostQuery, true);
	}

	if (gIsMonopolyRunning == true)
	{
		if (gMonopolyTeam == kbGetPlayerTeam(cMyID))
			defendingMonopoly = true;  // We're defending, let's not go launching any attacks
		else
			attackingMonopoly = true;  // We're attacking, focus on trade posts
	}
	else if (isItalianWars == true && kbCounterGetCurrentValue("leagueVictoryTimer") < 600)
	{
		// Italian Wars League Victory as Trade Monopoly.
		cityStateQuery = createSimpleUnitQuery(cUnitTypedeSPCSocketCityState, cPlayerRelationAny, cUnitStateAny);
		numberFound = kbUnitQueryExecute(cityStateQuery);

		for (i = 0; i < numberFound; i++)
		{
			unitID = kbUnitQueryGetResult(cityStateQuery, i);
			if (kbIsPlayerAlly(kbUnitGetPlayerID(unitID)) == true)
			{
				numberControlledCityStates++;
			}
		}

		if (numberControlledCityStates > (numberFound / 2))
		{
			attackingMonopoly = true;
		}
		else
		{
			defendingMonopoly = true;
		}
	}

	if (gIsKOTHRunning == true || aiIsKOTHAllowed() == true)
	{
		if (gKOTHTeam == kbGetPlayerTeam(cMyID))
			defendingKOTH = true;  // We're defending, let's not go launching any attacks
		else
			attackingKOTH = true;  // We're attacking, focus on the hill
	}

	bool reservePlanReady = true;
	if (gLandReservePlan < 0)
	{
		reservePlanReady = false;
	}
	else if ((aiPlanGetState(gLandReservePlan) < 0) ||
		(aiPlanGetActive(gLandReservePlan) == false))
	{
		reservePlanReady = false;
	}
	if (reservePlanReady == false)
	{
		if (currentPlayer >= 0 || currentBaseIndex >= 0)
		{
			debugEvent("MIL-SCAN", "interrupted: missing land reserve plan");
		}
		debugEvent("MIL-INVARIANT", "attack scan abandoned: land reserve plan is missing");
		currentPlayer = -1;
		currentBaseIndex = -1;
		targetBaseID = -1;
		targetBaseLocation = cInvalidVector;
		targetPlayer = 2;
		targetIsEnemy = true;
		targetShouldAttack = false;
		targetAffordable = 0.0;
		targetBaseAssets = 0.0;
		targetDistancePenalty = 0.0;
		targetScore = 0.0;
		maxBaseAssets = 100.0;
		xsSetRuleMinIntervalSelf(15);
		return;
	}

	numberUnits = aiPlanGetNumberUnits(gLandReservePlan, cUnitTypeLogicalTypeLandMilitary);

	for (i = 0; < numberUnits)
	{
		unitID = aiPlanGetUnitByIndex(gLandReservePlan, i);
		puid = kbUnitGetProtoUnitID(unitID);
		armyPower = armyPower + getMilitaryUnitStrength(puid);
	}

	// A negative cursor starts a fresh scan and clears every accumulated target field.
	if (currentPlayer < 0 || currentBaseIndex < 0)
	{
		targetBaseID = -1;
		targetBaseLocation = cInvalidVector;
		targetPlayer = 2;
		targetIsEnemy = true;
		targetShouldAttack = false;
		targetAffordable = 0.0;
		targetBaseAssets = 0.0;
		targetDistancePenalty = 0.0;
		targetScore = 0.0;
		maxBaseAssets = 100.0;
		currentPlayer = 0;
		currentBaseIndex = 0;
	}

	// Go through all players' bases and calculate values for comparison.
	for (player = currentPlayer; < cNumberPlayers)
	{
		cityStateQuery = -1;
		crateFlagQuery = -1;

		if (player == 0)
		{
			if (isItalianWars == true)
			{
				cityStateQuery = createSimpleUnitQuery(cUnitTypedeSPCSocketCityState, 0, cUnitStateAny);
				if (cityStateQuery < 0)
				{
					currentBaseIndex = 0;
					debugEvent("MIL-INVARIANT", "attack scan: failed to create Gaia city-state query");
					continue;
				}
			}
			else if (isNorthernWars == true)
			{
				// This pseudo-base query belongs exclusively to the Gaia iteration.
				crateFlagQuery = createSimpleUnitQuery(cUnitTypedeSPCCrateFlag, 0, cUnitStateAny);
				if (crateFlagQuery < 0)
				{
					currentBaseIndex = 0;
					debugEvent("MIL-INVARIANT", "attack scan: failed to create Gaia crate-objective query");
					continue;
				}
			}
			else
			{
				currentBaseIndex = 0;
				continue;
			}
		}

		if (cityStateQuery >= 0)
		{
			numberBases = kbUnitQueryExecute(cityStateQuery);
			isEnemy = true;
		}
		else if (crateFlagQuery >= 0)
		{
			// Creation, execution, and result access all remain inside player 0.
			numberBases = kbUnitQueryExecute(crateFlagQuery);
			isEnemy = true;
		}
		else
		{
			if (player == cMyID || kbHasPlayerLost(player) == true)
			{
				currentBaseIndex = 0;
				continue;
			}

			numberBases = kbBaseGetNumber(player);
			isEnemy = kbIsPlayerEnemy(player);


			if (isEnemy == true && (cvPlayerToAttack > 0 && cvPlayerToAttack != player && kbHasPlayerLost(cvPlayerToAttack) == false))
			{
				currentBaseIndex = 0;
				continue;
			}
		}

		for (baseIndex = currentBaseIndex; < numberBases)
		{
			int cityStateID = -1;
			int crateFlagID = -1;

			// Bound each invocation even when a candidate is later skipped.
			if (numberBasesProcessed >= 2)
			{
				currentPlayer = player;
				currentBaseIndex = baseIndex;
				xsSetRuleMinIntervalSelf(1);
				debugMilitary("attackManager: splitting base scan across updates");
				return;
			}
			numberBasesProcessed++;

			if (cityStateQuery >= 0) // City state, treat the Gaia-controlled socket as an enemy base.
			{
				baseID = -1;
				cityStateID = kbUnitQueryGetResult(cityStateQuery, baseIndex);
				baseLocation = kbUnitGetPosition(cityStateID);
				baseDistance = 30.0;
			}
			else if (crateFlagQuery >= 0)
			{
				baseID = -1;
				crateFlagID = kbUnitQueryGetResult(crateFlagQuery, baseIndex);
				baseLocation = kbUnitGetPosition(crateFlagID);
				baseDistance = 20.0;
			}
			else
			{
				baseID = kbBaseGetIDByIndex(player, baseIndex);
				baseLocation = kbBaseGetLocation(player, baseID);
				baseDistance = kbBaseGetDistance(player, baseID);
			}

			kbUnitQuerySetPlayerID(baseQuery, player);
			kbUnitQuerySetState(baseQuery, cUnitStateABQ);
			kbUnitQuerySetPosition(baseQuery, baseLocation);
			kbUnitQuerySetMaximumDistance(baseQuery, baseDistance);

			if (crateFlagQuery >= 0)
			{
				kbUnitQuerySetUnitType(baseQuery, cUnitTypeAbstractResourceCrate);
			}
			else
			{
				kbUnitQuerySetUnitType(baseQuery, cUnitTypeHasBountyValue);
			}
			kbUnitQueryResetResults(baseQuery);
			numberFound = kbUnitQueryExecute(baseQuery);

			buildingPower = 0.0;
			militaryPower = 0.0;
			enemyMilitaryPower = 0.0;
			if (cityStateQuery >= 0)
			{
				// Gaia city states are strategic pseudo-bases, so prioritize them over everything.
				baseAssets = 99999.0;
			}
			else if (crateFlagQuery >= 0)
			{
				// Great Northern War objectives are worth 300 points per nearby resource crate.
				baseAssets = numberFound * 300.0;
				numberFound = 0; // Crates are already scored; do not run the normal bounty loop.
			}
			else
			{
				baseAssets = 0.0;
			}
			isKOTH = false;
			isTradingPost = false;
			shouldAttack = true;
			isCityState = false;

			if (isEnemy == true)
			{
				if (currentTime - gLastAttackMissionTime < gAttackMissionInterval)
				{
					shouldAttack = false;
				}
			}
			else
			{
				if (currentTime - gLastDefendMissionTime < gDefendMissionInterval)
				{
					shouldAttack = false;
				}
			}

			for (i = 0; < numberFound)
			{
				unitID = kbUnitQueryGetResult(baseQuery, i);
				puid = kbUnitGetProtoUnitID(unitID);
				switch (puid)
				{
				case cUnitTypeypKingsHill:
				{
					baseAssets = baseAssets + 1600.0;
					isKOTH = true;
					break;
				}
				case cUnitTypeTownCenter:
				case cUnitTypedeSPCCommandPost:
				{
					baseAssets = baseAssets + 1000.0;
					break;
				}
				// Buildings generating resources.
				case cUnitTypeBank:
				{
					baseAssets = baseAssets + 800.0;
					break;
				}
				case cUnitTypeFactory:
				{
					baseAssets = baseAssets + 1600.0;
					break;
				}
				case cUnitTypeypWCPorcelainTower2:
				{
					baseAssets = baseAssets + 800.0;
					break;
				}
				case cUnitTypeypWCPorcelainTower3:
				{
					baseAssets = baseAssets + 1200.0;
					break;
				}
				case cUnitTypeypWCPorcelainTower4:
				case cUnitTypeypWCPorcelainTower5:
				{
					baseAssets = baseAssets + 1600.0;
					break;
				}
				case cUnitTypeypShrineJapanese:
				{
					baseAssets = baseAssets + 200.0;
					break;
				}
				case cUnitTypeypWJToshoguShrine2:
				case cUnitTypeypWJToshoguShrine3:
				case cUnitTypeypWJToshoguShrine4:
				case cUnitTypeypWJToshoguShrine5:
				{
					baseAssets = baseAssets + 400.0;
					break;
				}
				case cUnitTypedeHouseInca:
				case cUnitTypedeTorp:
				{
					baseAssets = baseAssets + 200.0;
					break;
				}
				case cUnitTypedeMountainMonastery:
				case cUnitTypedeUniversity:
				{
					baseAssets = baseAssets + 300.0;
					break;
				}
				// Buildings automatically creating military units.
				case cUnitTypeypWCSummerPalace2:
				case cUnitTypeypWCSummerPalace3:
				case cUnitTypeypWCSummerPalace4:
				case cUnitTypeypWCSummerPalace5:
				case cUnitTypeypDojo:
				{
					baseAssets = baseAssets + 1200.0;
					break;
				}
				// Buildings with HC drop off point.
				case cUnitTypeFortFrontier:
				case cUnitTypeOutpost:
				case cUnitTypeBlockhouse:
				case cUnitTypeNoblesHut:
				case cUnitTypeypWIAgraFort2:
				case cUnitTypeypWIAgraFort3:
				case cUnitTypeypWIAgraFort4:
				case cUnitTypeypWIAgraFort5:
				case cUnitTypeypCastle:
				case cUnitTypeYPOutpostAsian:
				case cUnitTypedeIncaStronghold:
				case cUnitTypedeTower:
				// Military buildings.
				case cUnitTypeBarracks:
				case cUnitTypeStable:
				case cUnitTypeArtilleryDepot:
				case cUnitTypeCorral:
				case cUnitTypeypWarAcademy:
				case cUnitTypeYPBarracksIndian:
				case cUnitTypeypCaravanserai:
				case cUnitTypeypBarracksJapanese:
				case cUnitTypeypStableJapanese:
				case cUnitTypedeKallanka:
				case cUnitTypedeWarCamp:
				case cUnitTypedeHospital:
				case cUnitTypedeCommandery:
				{
					baseAssets = baseAssets + 100.0;
					break;
				}
				case cUnitTypedePalace:
				{
					baseAssets = baseAssets + 200.0;
					break;
				}
				// Villagers.
				case cUnitTypeSettlerWagon:
				{
					baseAssets = baseAssets + 400.0;
					break;
				}
				case cUnitTypeSettler:
				case cUnitTypeCoureur:
				case cUnitTypeCoureurCree:
				case cUnitTypeSettlerNative:
				case cUnitTypeypSettlerAsian:
				case cUnitTypeypSettlerIndian:
				case cUnitTypeypSettlerJapanese:
				case cUnitTypedeSettlerAfrican:
				{
					baseAssets = baseAssets + 200.0;
					break;
				}
				default:
				{
					if (kbUnitIsType(unitID, cUnitTypeTradingPost) == true)
					{
						if (isItalianWars == true && kbUnitGetSubCiv(unitID) == cCivSPCCityState)
						{
							baseAssets += 2000.0;
							isCityState = true;
						}
						else if (kbUnitGetSubCiv(unitID) >= 0)
						{
							baseAssets += 400.0;
						}
						else // Trade route trading post.
						{
							baseAssets += 1600.0;
						}
						isTradingPost = true;
					}
					break;
				}
				}
			}

			// Ignore base when we have no good targets to attack.
			if (baseAssets == 0.0)
			{
				continue;
			}

			// Prioritize trade monopoly and king's hill when active.
			if ((attackingMonopoly == true || defendingMonopoly == true) && isTradingPost == false)
			{
				// When Italian Wars League Victory is active, only attack those TPs.
				if (isItalianWars == false || isCityState == true)
				{
				shouldAttack = false;
				}
			}
			if ((attackingKOTH == true || defendingKOTH == true) && isKOTH == false)
			{
				shouldAttack = false;
			}

			if (isEnemy == false)
			{
				kbUnitQuerySetPlayerRelation(baseEnemyQuery, cPlayerRelationEnemyNotGaia);
				kbUnitQuerySetState(baseEnemyQuery, cUnitStateABQ);
				kbUnitQuerySetPosition(baseEnemyQuery, baseLocation);
				kbUnitQuerySetMaximumDistance(baseEnemyQuery, baseDistance + 10.0);

				kbUnitQuerySetUnitType(baseEnemyQuery, cUnitTypeLogicalTypeLandMilitary);
				kbUnitQueryResetResults(baseEnemyQuery);
				numberEnemyFound = kbUnitQueryExecute(baseEnemyQuery);

				for (i = 0; < numberEnemyFound)
				{
					unitID = kbUnitQueryGetResult(baseEnemyQuery, i);
					puid = kbUnitGetProtoUnitID(unitID);
					enemyMilitaryPower = enemyMilitaryPower + getMilitaryUnitStrength(puid);
				}

				if (enemyMilitaryPower == 0.0)
				{
					continue;
				}
			}

			for (i = 0; < numberFound)
			{
				unitID = kbUnitQueryGetResult(baseQuery, i);
				puid = kbUnitGetProtoUnitID(unitID);

				switch (puid)
				{
					case cUnitTypeFortFrontier:
					{
						buildingPower = buildingPower + 10.0;
						break;
					}
					case cUnitTypeYPOutpostAsian:
					case cUnitTypeOutpost:
					case cUnitTypeBlockhouse:
					{
						buildingPower = buildingPower + 3.0;
						break;
					}
					case cUnitTypeNoblesHut:
					case cUnitTypeypWIAgraFort2:
					case cUnitTypeypWIAgraFort3:
					case cUnitTypeypWIAgraFort4:
					case cUnitTypeypWIAgraFort5:
					case cUnitTypedeIncaStronghold:
					case cUnitTypeTownCenter:
					case cUnitTypedeSPCCommandPost:
					{
						buildingPower = buildingPower + 4.0;
						break;
					}
					case cUnitTypeypCastle:
					{
						buildingPower = buildingPower + 3.5;
						break;
					}
				}

				if (kbProtoUnitIsType(cMyID, puid, cUnitTypeLogicalTypeLandMilitary) == true)
				{
					militaryPower = militaryPower + getMilitaryUnitStrength(puid);
				}
			}

			// Avoid division by 0.
			if ((militaryPower + buildingPower) < 1.0)
			{
				militaryPower = 1.0;
				buildingPower = 0.0;
			}

			if (isEnemy == true)
			{
				// Do we have enough power to defeat the target base?
				if (armyPower < militaryPower && availableMilitaryPop > 0)
				{
					shouldAttack = false;
				}
			}
			else
			{
				// Is my ally really in trouble and can I handle the attack?
				if ((militaryPower + buildingPower > enemyMilitaryPower) ||
					(armyPower + militaryPower + buildingPower < enemyMilitaryPower * 0.8))
				{
					shouldAttack = false;
				}
			}

			// Prioritize defending allies.
			if (isEnemy == true && targetIsEnemy == false)
			{
				shouldAttack = false;
			}

			if (baseAssets > maxBaseAssets)
			{
				maxBaseAssets = baseAssets;
				targetScore = (targetBaseAssets / maxBaseAssets) * targetAffordable * targetDistancePenalty;
			}

			if (isEnemy == true)
			{
				affordable = armyPower / (militaryPower + buildingPower);
			}
			else
			{
				affordable = (armyPower + militaryPower + buildingPower) / enemyMilitaryPower;
			}

			// Adjust for distance. If < 100m, leave as is.  Over 100m to 400m, penalize 10% per 100m.
			distancePenalty = getDistance(mainBaseLocation, baseLocation) / 1000.0;
			if (distancePenalty > 0.4)
			{
				distancePenalty = 0.4;
			}
			// Increase penalty by 40% if transporting is required.
			baseAreaGroup = kbAreaGroupGetIDByPosition(baseLocation);
			if (mainAreaGroup != baseAreaGroup)
			{
				distancePenalty = distancePenalty + 0.4;
			}
			distancePenalty = 1.0 - distancePenalty;

			score = (baseAssets / maxBaseAssets) * affordable * distancePenalty;
			if (score > targetScore || (shouldAttack == true && targetShouldAttack == false))
			{
				targetBaseID = baseID;
				targetBaseLocation = baseLocation;
				targetPlayer = player;
				targetIsEnemy = isEnemy;
				targetBaseAssets = baseAssets;
				targetAffordable = affordable;
				targetDistancePenalty = distancePenalty;
				targetScore = score;
				targetShouldAttack = shouldAttack;
			}
		}

		// The next player always starts at its first base.
		currentBaseIndex = 0;

		// If we found a city state target, break now.
		if (isItalianWars == true && cityStateQuery >= 0 && targetShouldAttack == true)
		{
			break;
		}
	}

	// Snapshot the completed scan, then clear every static field before any abandonment or plan creation path.
	int selectedBaseID = targetBaseID;
	vector selectedBaseLocation = targetBaseLocation;
	int selectedPlayer = targetPlayer;
	bool selectedIsEnemy = targetIsEnemy;
	bool selectedShouldAttack = targetShouldAttack;

	currentPlayer = -1;
	currentBaseIndex = -1;
	targetBaseID = -1;
	targetBaseLocation = cInvalidVector;
	targetPlayer = 2;
	targetIsEnemy = true;
	targetShouldAttack = false;
	targetAffordable = 0.0;
	targetBaseAssets = 0.0;
	targetDistancePenalty = 0.0;
	targetScore = 0.0;
	maxBaseAssets = 100.0;
	xsSetRuleMinIntervalSelf(15);
	debugEvent("MIL-SCAN", "completed: target player " + selectedPlayer + ", base " + selectedBaseID);

	if ((selectedShouldAttack == false) || (selectedBaseLocation == cInvalidVector))
	{
		// If we got nothing, and KOTH is active, grab the KOTH location.
		if (defendingKOTH == true || attackingKOTH == true)
		{
			int kothID = getUnit(cUnitTypeypKingsHill, cPlayerRelationAny, cUnitStateAlive);
			if (kothID < 0)
			{
				debugEvent("MIL-INVARIANT", "KOTH target requested but no King's Hill was found");
				return;
			}
			selectedIsEnemy = attackingKOTH;
			selectedPlayer = kbUnitGetPlayerID(kothID);
			selectedBaseID = -1;
			selectedBaseLocation = kbUnitGetPosition(kothID);
			selectedShouldAttack = true;
		}
		else
		{
			return;
		}
	}

	// Update target player after KOTH fallback has had a chance to replace the scanned target.
	if (selectedIsEnemy == true)
	{
		aiSetMostHatedPlayerID(selectedPlayer);
	}

	vector gatherPoint = kbBaseGetMilitaryGatherPoint(cMyID, mainBaseID);
	if (selectedIsEnemy == true)
	{
		planID = aiPlanCreate("Attack Player " + selectedPlayer + " Base " + selectedBaseID, cPlanCombat);
		if (planID < 0)
		{
			debugEvent("MIL-INVARIANT", "failed to create land attack mission");
			return;
		}

		aiPlanSetVariableInt(planID, cCombatPlanCombatType, 0, cCombatPlanCombatTypeAttack);
		if (selectedBaseID >= 0)
		{
			aiPlanSetVariableInt(planID, cCombatPlanTargetMode, 0, cCombatPlanTargetModeBase);
			aiPlanSetVariableInt(planID, cCombatPlanTargetBaseID, 0, selectedBaseID);
		}
		else
		{
			aiPlanSetVariableInt(planID, cCombatPlanTargetMode, 0, cCombatPlanTargetModePoint);
		}
		aiPlanSetVariableInt(planID, cCombatPlanTargetPlayerID, 0, selectedPlayer);
		aiPlanSetVariableVector(planID, cCombatPlanTargetPoint, 0, selectedBaseLocation);
		aiPlanSetVariableVector(planID, cCombatPlanGatherPoint, 0, gatherPoint);
		aiPlanSetVariableFloat(planID, cCombatPlanGatherDistance, 0, 40.0);

		aiPlanSetVariableInt(planID, cCombatPlanAttackRoutePattern, 0, cCombatPlanAttackRoutePatternRandom);

		// Point pseudo-targets (KOTH, city states, and crate objectives) have no base route.
		int routeID = -1;
		if (selectedBaseID >= 0)
		{
			routeID = cvCreateBaseAttackRoute(selectedPlayer, selectedBaseID);
		}
		if (routeID >= 0)
		{
			aiPlanSetVariableInt(planID, cCombatPlanAttackRouteID, 0, routeID);
			// aiPlanSetVariableBool(planID, cCombatPlanRefreshAttackRoute, 0, false);
		}

		if (difficulty >= cDifficultyHard)
		{
			aiPlanSetVariableBool(planID, cCombatPlanAllowMoreUnitsDuringAttack, 0, true);
			aiPlanSetVariableInt(planID, cCombatPlanRefreshFrequency, 0, 300);
			aiPlanSetVariableInt(planID, cCombatPlanDoneMode, 0,
				cCombatPlanDoneModeRetreat | cCombatPlanDoneModeBaseGone);
			aiPlanSetVariableInt(planID, cCombatPlanRetreatMode, 0,
				cCombatPlanRetreatModeOutnumbered);
			// updateMilitaryTrainPlanBuildings(gForwardBaseID); TODO (James)
		}
		else
		{
			aiPlanSetVariableInt(planID, cCombatPlanRefreshFrequency, 0, 1000);
			aiPlanSetVariableInt(planID, cCombatPlanDoneMode, 0, cCombatPlanDoneModeBaseGone);
		}
		// If we do not have a base, destroy the plan when we have no targets.
		if (selectedBaseID < 0)
		{
			aiPlanSetVariableInt(planID, cCombatPlanDoneMode, 0, cCombatPlanDoneModeNoTarget | aiPlanGetVariableInt(planID, cCombatPlanDoneMode, 0));
			aiPlanSetVariableInt(planID, cCombatPlanNoTargetTimeout, 0, 30000);
		}
		aiPlanSetBaseID(planID, mainBaseID);
		aiPlanSetInitialPosition(planID, gatherPoint);

		addUnitsToMilitaryPlan(planID);

		registerTransientLandCombatMission(planID, cLandMissionSourceAutoAttack);
		aiPlanSetActive(planID);

		gLastAttackMissionTime = xsGetTime();
		debugMilitary("***** LAUNCHING ATTACK on player " + selectedPlayer + " base " + selectedBaseID);
		debugEvent("MIL-MISSION", "created land attack plan " + planID + " for player " + selectedPlayer);
	}
	else
	{
		planID = aiPlanCreate("Defend Player " + selectedPlayer + " Base " + selectedBaseID, cPlanCombat);
		if (planID < 0)
		{
			debugEvent("MIL-INVARIANT", "failed to create ally-defense mission");
			return;
		}

		aiPlanSetVariableInt(planID, cCombatPlanCombatType, 0, cCombatPlanCombatTypeDefend);
		if (selectedBaseID >= 0)
		{
			aiPlanSetVariableInt(planID, cCombatPlanTargetMode, 0, cCombatPlanTargetModeBase);
			aiPlanSetVariableInt(planID, cCombatPlanTargetBaseID, 0, selectedBaseID);
		}
		else
		{
			aiPlanSetVariableInt(planID, cCombatPlanTargetMode, 0, cCombatPlanTargetModePoint);
		}
		aiPlanSetVariableInt(planID, cCombatPlanTargetPlayerID, 0, selectedPlayer);
		aiPlanSetVariableVector(planID, cCombatPlanTargetPoint, 0, selectedBaseLocation);
		aiPlanSetVariableInt(planID, cCombatPlanRefreshFrequency, 0, difficulty >= cDifficultyHard ? 300 : 1000);
		aiPlanSetVariableInt(planID, cCombatPlanDoneMode, 0, cCombatPlanDoneModeNoTarget | cCombatPlanDoneModeRetreat);
		aiPlanSetVariableInt(planID, cCombatPlanNoTargetTimeout, 0, 30000);
		aiPlanSetVariableInt(planID, cCombatPlanRetreatMode, 0, cCombatPlanRetreatModeOutnumbered);
		aiPlanSetOrphan(planID, true);

		addUnitsToMilitaryPlan(planID);

		registerTransientLandCombatMission(planID, cLandMissionSourceAutoDefend);
		aiPlanSetActive(planID);

		gLastDefendMissionTime = xsGetTime();
		debugMilitary("***** DEFENDING player " + selectedPlayer + " base " + selectedBaseID);
		debugEvent("MIL-MISSION", "created ally-defense plan " + planID + " for player " + selectedPlayer);
	}
}

void navalAttackPlanHandler(int planID = -1)
{
	if (aiPlanGetState(planID) == -1)
	{
		// Done so reset the global.
		gNavyAttackPlan = -1;
	}
}

/* Naval Priorities explained:
	Defending = 15 when not under attack so war ships that can fish will do so.
	Fishing = 19.
	Exploring = 20 so fishing ships can be used for it.
	Repairing = 22 so the war ships do defend but will chose repairing over fishing.
	Defending = 25 when under attack so war ships that can fish will actually fight.
	Attacking = 60 so all war ships will go on the attack.
	Transport = 100 so the ships will actually deliver the units reliably.
*/
//==============================================================================
// waterAttack
// Creates the attack plans for our naval units.
//==============================================================================
rule waterAttack
inactive
minInterval 30
{
	int time = xsGetTime();
	if ((gLastNavalAttackTime > time - gAttackMissionInterval) || (aiTreatyActive() == true))
	{
		return;
	}
	
	if (gNavyAttackPlan >= 0)
	{
		return; // We don't want multiple attack plans.
	}
	
	if (kbUnitCount(cMyID, cUnitTypeAbstractWarShip, cUnitStateAlive) < 3)
	{
		return; // We don't attack with fewer than 3 war ships.
	}
	
	int targetDockID = getClosestUnit(cUnitTypeAbstractDock, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
		gNavyVec, 400.0); // Get any enemy Dock within 400 range of our gNavyVec to attack.
	
	if (targetDockID >= 0) // There's something to attack.
	{
		vector targetDockPosition = kbUnitGetPosition(targetDockID);
		int navalTargetPlayer = kbUnitGetPlayerID(targetDockID);
		
		gNavyAttackPlan = aiPlanCreate("NAVAL Attack Player: " + navalTargetPlayer + ", targetDockID: " + targetDockID, cPlanCombat);
		
		aiPlanAddUnitType(gNavyAttackPlan, cUnitTypeAbstractWarShip, 3, 200, 200);
		aiPlanSetVariableInt(gNavyAttackPlan, cCombatPlanCombatType, 0, cCombatPlanCombatTypeAttack);
		aiPlanSetVariableInt(gNavyAttackPlan, cCombatPlanTargetMode, 0, cCombatPlanTargetModePoint);
		aiPlanSetVariableInt(gNavyAttackPlan, cCombatPlanTargetPlayerID, 0, navalTargetPlayer);
		aiPlanSetVariableVector(gNavyAttackPlan, cCombatPlanTargetPoint, 0, targetDockPosition);
		aiPlanSetVariableVector(gNavyAttackPlan, cCombatPlanGatherPoint, 0, gNavyVec);
		aiPlanSetVariableFloat(gNavyAttackPlan, cCombatPlanGatherDistance, 0, 40.0);
		aiPlanSetVariableInt(gNavyAttackPlan, cCombatPlanAttackRoutePattern, 0, cCombatPlanAttackRoutePatternRandom);

		if (cDifficultyCurrent >= cDifficultyHard)
		{
			aiPlanSetVariableBool(gNavyAttackPlan, cCombatPlanAllowMoreUnitsDuringAttack, 0, true);
			aiPlanSetVariableInt(gNavyAttackPlan, cCombatPlanRefreshFrequency, 0, 300);
		}
		else
		{
			aiPlanSetVariableInt(gNavyAttackPlan, cCombatPlanRefreshFrequency, 0, 1000);
			
		}
		aiPlanSetVariableInt(gNavyAttackPlan, cCombatPlanDoneMode, 0, cCombatPlanDoneModeRetreat | cCombatPlanDoneModeNoTarget);
		aiPlanSetVariableInt(gNavyAttackPlan, cCombatPlanRetreatMode, 0, cCombatPlanRetreatModeOutnumbered);
		aiPlanSetVariableInt(gNavyAttackPlan, cCombatPlanNoTargetTimeout, 0, 30000);
		aiPlanSetBaseID(gNavyAttackPlan, kbUnitGetBaseID(getUnit(gDockUnit, cMyID, cUnitStateAlive)));
		aiPlanSetInitialPosition(gNavyAttackPlan, gNavyVec);

		aiPlanSetActive(gNavyAttackPlan);
		gLastNavalAttackTime = time;
		debugMilitary("***** LAUNCHING NAVAL ATTACK on player: " + navalTargetPlayer + ", targetDockID: " + targetDockID);
		aiPlanSetEventHandler(gNavyAttackPlan, cPlanEventStateChange, "navalAttackPlanHandler");
	}
}

//==============================================================================
// waterDefend
// Creates and manages the persistent defend plan for our naval units.
//==============================================================================
rule waterDefend
inactive
minInterval 10
{
	if (gNavyDefendPlan < 0) // First run, create a persistent defend plan.
	{
		gNavyDefendPlan = aiPlanCreate("Water Defend", cPlanCombat);

		aiPlanSetVariableInt(gNavyDefendPlan, cCombatPlanCombatType, 0, cCombatPlanCombatTypeDefend);
		aiPlanSetVariableInt(gNavyDefendPlan, cCombatPlanTargetMode, 0, cCombatPlanTargetModePoint);
		aiPlanSetVariableInt(gNavyDefendPlan, cCombatPlanTargetPlayerID, 0, cMyID);
		aiPlanSetVariableVector(gNavyDefendPlan, cCombatPlanTargetPoint, 0, gNavyVec);
		aiPlanSetInitialPosition(gNavyDefendPlan, gNavyVec);
		aiPlanSetVariableVector(gNavyDefendPlan, cCombatPlanGatherPoint, 0, gNavyVec);
		aiPlanSetVariableFloat(gNavyDefendPlan, cCombatPlanGatherDistance, 0, 40.0);
		aiPlanSetVariableInt(gNavyDefendPlan, cCombatPlanRefreshFrequency, 0, cDifficultyCurrent >= cDifficultyHard ? 300 : 1000);
		aiPlanAddUnitType(gNavyDefendPlan, cUnitTypeAbstractWarShip, 0, 200, 200);
		
		debugMilitary("Creating primary navy defend plan at: " + gNavyVec);
		aiPlanSetActive(gNavyDefendPlan);
	}
	
	int enemyQuery = createSimpleUnitQuery(cUnitTypeAbstractWarShip, cPlayerRelationEnemyNotGaia, cUnitStateAlive);
	kbUnitQuerySetSeeableOnly(enemyQuery, true); // Only stop fishing when the enemy is actually near us.
	int numberFound = kbUnitQueryExecute(enemyQuery);

	if (numberFound > 0)
	{
		aiPlanSetDesiredPriority(gNavyDefendPlan, 25); // Above fishing when there are enemies around.
	}
	else
	{
		aiPlanSetDesiredPriority(gNavyDefendPlan, 15); // Below fishing when there are no enemies around.
	}
}

//==============================================================================
/* navyManager
   Create enough Docks for our age and difficulty.
   Create maintain plans for navy unit lines. Control 'maintain' levels.
   Monitor if we need to repair ships.
*/
//==============================================================================
rule navyManager
inactive
minInterval 30
{
	int age = kbGetAge();
	
	/////////////////
	// Maintain war ships part.
	/////////////////
	int ownDockID = getUnit(gDockUnit, cMyID, cUnitStateAlive);
	vector ownDockPosition = kbUnitGetPosition(ownDockID);

	if (gCaravelMaintain < 0) // First run, initiliaze plans.
	{
		// Don't fire up maintain plans until we have a base ID, and repairing is no use either.
		// Only start training war ships when we're 5 minutes away from treaty ending.
		if ((ownDockID < 0) || (aiTreatyGetEnd() > xsGetTime() + 5 * 60 * 1000))
		{
			return; 
		}
		int baseID = kbUnitGetBaseID(ownDockID);
		
		// These initial maintain amounts mean nothing and get instantly overwritten.
		if (cMyCiv == cCivXPAztec)
		{
			gCaravelMaintain = createSimpleMaintainPlan(gCaravelUnit, 10, false, baseID, 1); // xpWarCanoe
			gFrigateMaintain = createSimpleMaintainPlan(gGalleonUnit, 5, false, baseID, 1);  // xpTlalocCanoe
		}
		else if (cMyCiv == cCivDEInca)
		{
			gCaravelMaintain = createSimpleMaintainPlan(gCaravelUnit, 8, false, baseID, 1); // deChinchaRaft
		}
		else if (civIsNative() == true)
		{
			gCaravelMaintain = createSimpleMaintainPlan(gCaravelUnit, 10, false, baseID, 1); // xpWarCanoe
			gGalleonMaintain = createSimpleMaintainPlan(gGalleonUnit, 20, false, baseID, 1); // Canoe
		}
		else if ((cMyCiv == cCivChinese) || (cMyCiv == cCivSPCChinese))
		{
			gCaravelMaintain = createSimpleMaintainPlan(gCaravelUnit, 5, false, baseID, 1); // War Junk
			gFrigateMaintain = createSimpleMaintainPlan(gFrigateUnit, 3, false, baseID, 1); // Fuchuan
			gMonitorMaintain = createSimpleMaintainPlan(gMonitorUnit, 2, false, baseID, 1);
		}
		else if (civIsAfrican() == true)
		{
			gCaravelMaintain = createSimpleMaintainPlan(gCaravelUnit, 5, false, baseID, 1); // Battle Canoe
			gFrigateMaintain = createSimpleMaintainPlan(gFrigateUnit, 2, false, baseID, 1); // Dhow/Xebec
			gMonitorMaintain = createSimpleMaintainPlan(gMonitorUnit, 2, false, baseID, 1); // Cannon Boat
		}
		else // Europeans.
		{
			gCaravelMaintain = createSimpleMaintainPlan(gCaravelUnit, 5, false, baseID, 1);
			gGalleonMaintain = createSimpleMaintainPlan(gGalleonUnit, 3, false, baseID, 1);
			gFrigateMaintain = createSimpleMaintainPlan(gFrigateUnit, 3, false, baseID, 1);
			gMonitorMaintain = createSimpleMaintainPlan(gMonitorUnit, 2, false, baseID, 1);
		}
	}

	int numberCaravels = 0;
	int numberGalleons = 0;
	int numberFrigates = 0;
	int numberMonitors = 0;

	if ((gStartOnDifferentIslands == true) ||
		(gTimeToFish == true) ||
		(age >= cAge3))
	{
		int navyQuery = -1;
		int navySize = 0;
		int unitID = -1;
		int puid = -1;
		
		// We either focus on an enemy player which we find by searching for a Dock.
		// Or if we don't find a Dock we see if we're being "attacked" and focus on some of those ships.
		int navyEnemyPlayer = kbUnitGetPlayerID(getClosestUnit(cUnitTypeAbstractDock, cPlayerRelationEnemyNotGaia,
			cUnitStateAlive, gNavyVec, 400.0));
		if (navyEnemyPlayer < 0)
		{
			navyEnemyPlayer = kbUnitGetPlayerID(getUnitByLocation(cUnitTypeAbstractWarShip, cPlayerRelationEnemyNotGaia,
				cUnitStateAlive, ownDockPosition, 100)); // If enemey ships are within 100 meters we still need to train ships to defend ourselves.
		}
		navyQuery = createSimpleUnitQuery(cUnitTypeAbstractWarShip, navyEnemyPlayer, cUnitStateAlive);
		navySize = kbUnitQueryExecute(navyQuery);

		for (i = 0; < navySize)
		{
			unitID = kbUnitQueryGetResult(navyQuery, i);
			puid = kbUnitGetProtoUnitID(unitID);
			gNetNavyValue += (kbUnitCostPerResource(puid, cResourceWood) + kbUnitCostPerResource(puid, cResourceGold) +
							kbUnitCostPerResource(puid, cResourceInfluence));
		}

		navyQuery = createSimpleUnitQuery(cUnitTypeAbstractWarShip, cMyID, cUnitStateABQ);
		navySize = kbUnitQueryExecute(navyQuery);

		int caravelLimit = 0;
		int galleonLimit = 0;
		int frigateLimit = 0;
		int monitorLimit = 0;

		caravelLimit = kbGetBuildLimit(cMyID, gCaravelUnit);
		if (cMyCiv == cCivXPAztec || cMyCiv == cCivXPIroquois || cMyCiv == cCivXPSioux)
		{
			galleonLimit = kbGetBuildLimit(cMyID, gGalleonUnit);
		}
		if (cMyCiv != cCivXPIroquois && cMyCiv != cCivXPSioux && cMyCiv != cCivDEInca && age >= cAge3)
		{
			frigateLimit = kbGetBuildLimit(cMyID, gFrigateUnit);
		}
		if (civIsNative() == false && age >= cAge4)
		{
			monitorLimit = kbGetBuildLimit(cMyID, gMonitorUnit);
		}

		for (i = 0; < navySize)
		{
			unitID = kbUnitQueryGetResult(navyQuery, i);
			puid = kbUnitGetProtoUnitID(unitID);
			gNetNavyValue -= (kbUnitCostPerResource(puid, cResourceWood) + kbUnitCostPerResource(puid, cResourceGold) +
							kbUnitCostPerResource(puid, cResourceInfluence));

			switch (puid)
			{
				case gCaravelUnit:
				{
				numberCaravels++;
				break;
				}
				case gGalleonUnit:
				{
				numberGalleons++;
				break;
				}
				case gFrigateUnit:
				{
				numberFrigates++;
				break;
				}
				case gMonitorUnit:
				{
				numberMonitors++;
				break;
				}
			}
		}

		// 1 More Caravel or equivalent amount of war ships than enemy.
		gNetNavyValue += 400.0;
		debugMilitary("Navy enemy player is " + navyEnemyPlayer + ", net navy value is " + gNetNavyValue);

		int caravelValue = kbUnitCostPerResource(gCaravelUnit, cResourceWood) +
							kbUnitCostPerResource(gCaravelUnit, cResourceGold);
		int galleonValue = kbUnitCostPerResource(gGalleonUnit, cResourceWood) +
							kbUnitCostPerResource(gGalleonUnit, cResourceGold);
		// African Dhows/Xebecs cost influence.
		int frigateValue = kbUnitCostPerResource(gFrigateUnit, cResourceWood) +
							kbUnitCostPerResource(gFrigateUnit, cResourceGold) +
							kbUnitCostPerResource(gFrigateUnit, cResourceInfluence);
		int monitorValue = kbUnitCostPerResource(gMonitorUnit, cResourceWood) +
							kbUnitCostPerResource(gMonitorUnit, cResourceGold);

		// Prioritize ships in the following order - Frigate, Caravel, Monitor, Galleon.
		while (gNetNavyValue > 0.0)
		{
			if (numberFrigates < frigateLimit)
			{
				numberFrigates++;
				gNetNavyValue -= frigateValue;
				continue;
			}
			if (numberCaravels < caravelLimit)
			{
				numberCaravels++;
				gNetNavyValue -= caravelValue;
				continue;
			}
			if (numberMonitors < monitorLimit)
			{
				numberMonitors++;
				gNetNavyValue -= monitorValue;
				continue;
			}
			if (numberGalleons < galleonLimit)
			{
				numberGalleons++;
				gNetNavyValue -= galleonValue;
				continue;
			}
			break;
		}
	}
	else
	{
		gNetNavyValue = 0;
	}

	if (gCaravelMaintain >= 0)
	{
		aiPlanSetVariableInt(gCaravelMaintain, cTrainPlanNumberToMaintain, 0, numberCaravels);
	}
	if (gGalleonMaintain >= 0)
	{
		aiPlanSetVariableInt(gGalleonMaintain, cTrainPlanNumberToMaintain, 0, numberGalleons);
	}
	if (gMonitorMaintain >= 0)
	{
		aiPlanSetVariableInt(gMonitorMaintain, cTrainPlanNumberToMaintain, 0, numberMonitors);
	}
	if (gFrigateMaintain >= 0)
	{
		aiPlanSetVariableInt(gFrigateMaintain, cTrainPlanNumberToMaintain, 0, numberFrigates);
	}
		
	/////////////////
	// Repair part.
	// We repurpose a combat defend plan to function as a repair plan by basically forcing a unit next to a Dock.
	/////////////////
	if (ownDockID < 0) // Destroy the repair plan as soon as we have no Docks left.
	{
		if (gNavyRepairPlan >= 0)
		{
			aiPlanDestroy(gNavyRepairPlan);
			gNavyRepairPlan = -1;
		}
	}
	else
	{
		if (gNavyRepairPlan < 0)
		{
			gNavyRepairPlan = aiPlanCreate("Navy Repair", cPlanCombat);

			aiPlanSetVariableInt(gNavyRepairPlan, cCombatPlanCombatType, 0, cCombatPlanCombatTypeDefend);
			aiPlanSetVariableInt(gNavyRepairPlan, cCombatPlanTargetMode, 0, cCombatPlanTargetModePoint);
			aiPlanSetVariableInt(gNavyRepairPlan, cCombatPlanTargetPlayerID, 0, cMyID);
			aiPlanSetVariableFloat(gNavyRepairPlan, cCombatPlanGatherDistance, 0, 10.0);
			aiPlanSetVariableInt(gNavyRepairPlan, cCombatPlanRefreshFrequency, 0, cDifficultyCurrent >= cDifficultyHard ? 300 : 1000);
			aiPlanAddUnitType(gNavyRepairPlan, cUnitTypeAbstractWarShip, 0, 0, 0); // Up later.
			
			debugMilitary("Creating primary navy repair plan at: " + ownDockPosition);
			aiPlanSetActive(gNavyRepairPlan);
		}
		aiPlanSetVariableVector(gNavyRepairPlan, cCombatPlanTargetPoint, 0, ownDockPosition);
		aiPlanSetInitialPosition(gNavyRepairPlan, ownDockPosition);
		aiPlanSetVariableVector(gNavyRepairPlan, cCombatPlanGatherPoint, 0, ownDockPosition);

		int bestUnitID = -1;
		unitID = aiPlanGetUnitByIndex(gNavyRepairPlan, 0);
		if (kbUnitGetHealth(unitID) > 0.95)
		{
			aiTaskUnitMove(unitID, gNavyVec);
			aiPlanAddUnit(gNavyDefendPlan, unitID);
		}

		// Look for a ship to repair.
		float unitHitpoints = 0.0;
		int unitPlanID = -1;
		float bestUnitHitpoints = 9999.0;
		int shipQueryID = createSimpleUnitQuery(cUnitTypeAbstractWarShip, cMyID, cUnitStateAlive);
		int numberFound = kbUnitQueryExecute(shipQueryID);
		for (i = 0; < numberFound)
		{
			unitID = kbUnitQueryGetResult(shipQueryID, i);
			unitPlanID = kbUnitGetPlanID(unitID);
			if ((aiPlanGetDesiredPriority(unitPlanID) > 22) || 
				(aiPlanGetType(unitPlanID) == cPlanTransport) ||
				(kbUnitGetHealth(unitID) > 0.95))
			{
				continue;
			}
			unitHitpoints = kbUnitGetCurrentHitpoints(unitID);
			if (unitHitpoints < bestUnitHitpoints)
			{
				bestUnitID = unitID;
				bestUnitHitpoints = unitHitpoints;
			}
		}

		if (bestUnitID >= 0)
		{
			aiPlanAddUnitType(gNavyRepairPlan, cUnitTypeAbstractWarShip, 1, 1, 1);
			aiPlanAddUnit(gNavyRepairPlan, bestUnitID);
		}
		else
		{
			aiPlanAddUnitType(gNavyRepairPlan, cUnitTypeAbstractWarShip, 0, 0, 0);
		}
	}
}


//==============================================================================
// Unit Picker Functions
//==============================================================================
void setUnitPickerCommon(int upID = -1)
{
	int targetPlayer = aiGetMostHatedPlayerID();

	kbUnitPickSetPreferenceWeight(upID, 1.0);
	kbUnitPickSetCombatEfficiencyWeight(upID, 2.0);
	// Late in game, less focus on taking down buildings.
	if (xsGetTime() < 900000 || kbUnitCount(targetPlayer, cUnitTypeBuilding, cUnitStateAlive | cUnitStateBuilding) >= 70)
		kbUnitPickSetBuildingCombatEfficiencyWeight(upID, 0.5);
	else
		kbUnitPickSetBuildingCombatEfficiencyWeight(upID, 0.0);
	kbUnitPickSetCostWeight(upID, 0.0);

	// Default to land units.
	kbUnitPickSetEnemyPlayerID(upID, targetPlayer);
	kbUnitPickSetAttackUnitType(upID, cUnitTypeLogicalTypeLandMilitary);

	// Set the default target types and weights, for use until we've seen enough actual units.
	kbUnitPickAddCombatEfficiencyType(upID, cUnitTypeLogicalTypeLandMilitary, 1.0);
	kbUnitPickAddBuildingCombatEfficiencyType(upID, cUnitTypeMilitaryBuilding, 1.0);
	kbUnitPickAddBuildingCombatEfficiencyType(upID, cUnitTypeAbstractTownCenter, 1.0);

	if (civIsAsian() == true && upID == gLandUnitPicker)
	{
		// Remove consulate units.
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractConsulateSiegeFortress, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractConsulateSiegeIndustrial, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractConsulateUnit, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractConsulateUnitColonial, 0.0);
	}
}

void setUnitPickerDisabledUnits(int upID = -1)
{
	kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractNativeWarrior, 0.0);
	kbUnitPickSetPreferenceFactor(upID, cUnitTypexpSpy, 0.0);
	kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractOutlaw, 0.0);
	kbUnitPickSetPreferenceFactor(upID, cUnitTypeGrenadier, 0.0);

	if (kbGetAge() < cAge3)
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeMercenary, 0.0);
	else
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeMercenary, 0.2);

	if (cMyCiv == cCivFrench)
	{
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeCoureur, 0.0);
	}

	if (cMyCiv == cCivDEItalians)
	{
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractBasilicaUnit, 0.0);
	}

	if (cMyCiv == cCivDEMaltese)
	{
		kbUnitPickSetPreferenceFactor(upID, cUnitTypedeMalteseGun, 0.0);
	}

	if (civIsNative() == true)
	{
		kbUnitPickSetPreferenceFactor(upID, cUnitTypexpWarrior, 0.0);
	}

	if (cMyCiv == cCivXPSioux)
	{
		kbUnitPickSetPreferenceFactor(upID, cUnitTypexpDogSoldier, 0.0);
	}

	if (cMyCiv == cCivXPAztec)
	{
		kbUnitPickSetPreferenceFactor(upID, cUnitTypexpMedicineManAztec, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypexpSkullKnight, 0.0);
	}

	kbUnitPickSetPreferenceFactor(upID, cUnitTypeypMercFlailiphant, 0.0);

	if ((cMyCiv == cCivIndians) || (cMyCiv == cCivSPCIndians))
	{
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeypSowarMansabdar, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeypRajputMansabdar, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeypSepoyMansabdar, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeypUrumiMansabdar, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeypZamburakMansabdar, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeypNatMercGurkhaJemadar, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeypMercFlailiphantMansabdar, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeypHowdahMansabdar, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeypMahoutMansabdar, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeypSiegeElephantMansabdar, 0.0);
	}

	if (cMyCiv == cCivDEInca)
	{
		kbUnitPickSetPreferenceFactor(upID, cUnitTypedeChasqui, 0.0);
	}

	if (civIsAsian() == true && upID == gLandUnitPicker)
	{
		// Remove Consulate units.
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractConsulateSiegeFortress, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractConsulateSiegeIndustrial, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractConsulateUnit, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractConsulateUnitColonial, 0.0);
	}

	if (civIsAfrican() == true)
	{
		// Exclude units costing influence, they are handled in influenceManager.
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeMercenary, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypedeBowmanLevy, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypedeSpearmanLevy, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypedeGunnerLevy, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypedeMaigadi, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypedeSebastopolMortar, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeFalconet, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeOrganGun, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeCulverin, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeMortar, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeypMahout, 0.0);
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeypHowdah, 0.0);
	}
}

void setUnitPickerPreference(int upID = -1)
{
	// Add the main unit lines
	if (upID < 0)
		return;

	if (kbGetAge() >= cAge3)
		kbUnitPickSetMinimumCounterModePop(upID, 20);

	kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractInfantry, 0.5);   // Range 0.0 to 1.0
	kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractArtillery, 0.2);
	kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractCavalry, 0.5);
	if (cMyCiv == cCivXPAztec)
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractLightInfantry, 0.5);
	if (cMyCiv == cCivDEEthiopians || cMyCiv == cCivDEInca)
		kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractCoyoteMan, 0.5);

	kbUnitPickRemovePreferenceFactor(upID, cUnitTypeAbstractBannerArmy);
	setUnitPickerDisabledUnits(upID);
}

//==============================================================================
// initUnitPicker
//==============================================================================
int initUnitPicker(string name = "BUG", int numberTypes = 1, int minUnits = 10, int maxUnits = 20, int minPop = -1, int maxPop = -1,
	int numberBuildings = 1, bool guessEnemyUnitType = false)
{
	// Create it.
	int upID = kbUnitPickCreate(name);
	if (upID < 0)
	{
		return (-1);
	}

	// Default init.
	kbUnitPickResetAll(upID);

	kbUnitPickSetPreferenceWeight(upID, 1.0);
	kbUnitPickSetCombatEfficiencyWeight(upID, 1.0); // Leave it at 1.0 to avoid messing up SPC balance
	kbUnitPickSetBuildingCombatEfficiencyWeight(upID, 0.25);
	kbUnitPickSetCostWeight(upID, 0.0);
	// Desired number units types, buildings.
	kbUnitPickSetDesiredNumberUnitTypes(upID, numberTypes, numberBuildings, true);
	// Min/Max units and Min/Max pop.
	kbUnitPickSetMinimumNumberUnits(upID, minUnits); // Sets "need" level on attack plans
	// Sets "max" level on attack plans, sets "numberToMaintain" on train.
	// plans for primary unit, half that for secondary, 1/4 for tertiary, etc.
	kbUnitPickSetMaximumNumberUnits(upID, maxUnits);

	// Default to land units.
	kbUnitPickSetEnemyPlayerID(upID, aiGetMostHatedPlayerID());
	kbUnitPickSetAttackUnitType(upID, cUnitTypeLogicalTypeLandMilitary);
	kbUnitPickSetGoalCombatEfficiencyType(upID, cUnitTypeLogicalTypeLandMilitary);

	// Set the default target types and weights, for use until we've seen enough actual units.
	// kbUnitPickAddCombatEfficiencyType(upID, cUnitTypeLogicalTypeLandMilitary, 1.0);
	kbUnitPickAddCombatEfficiencyType(upID, cUnitTypeSettler, 0.2);// We need to build units that can kill settlers efficiently.
	kbUnitPickAddCombatEfficiencyType(upID, cUnitTypeHussar, 0.2); // Major component.
	kbUnitPickAddCombatEfficiencyType(upID, cUnitTypeMusketeer, 0.4);   // Bigger component.
	kbUnitPickAddCombatEfficiencyType(upID, cUnitTypePikeman, 0.1);     // Minor component.
	kbUnitPickAddCombatEfficiencyType(upID, cUnitTypeCrossbowman, 0.1); // Minor component.

	kbUnitPickAddBuildingCombatEfficiencyType(upID, cUnitTypeMilitaryBuilding, 1.0);
	kbUnitPickAddBuildingCombatEfficiencyType(upID, cUnitTypeAbstractTownCenter, 1.0);

	setUnitPickerPreference(upID); // Set generic preferences for this civ.

	return (upID);
}

//==============================================================================
// Basilica Monitor
//
// The Basilica trains units via techs, so first run a unit pick then get
// corresponding techs.
//
//==============================================================================
int getBasilicaTechFromPapalUnitType(int unitTypeID = -1)
{
	int retVal = -1;

	switch (unitTypeID)
	{
		case cUnitTypedePapalGuard:
		{
			retVal = cTechDEBasilicaShipPapalGuards2;
			break;
		}
		case cUnitTypedeNMPandour:
		{
			retVal = cTechDEBasilicaShipPandours2;
			break;
		}
		case cUnitTypedeNMPapalElmetto:
		{
			retVal = cTechDEBasilicaShipPapalElmeti1;
			break;
		}
		case cUnitTypedeNMPapalZouave:
		{
			retVal = cTechDEBasilicaShipPapalZouave1;
			break;
		}
	}

	return (retVal);
}

int getPapalNumUnitsPerTech(int unitTypeID = -1)
{
	int retVal = -1;

	switch (unitTypeID)
	{
		case cUnitTypedePapalGuard:
		{
			retVal = 7;
			break;
		}
		case cUnitTypedeNMPandour:
		{
			retVal = 7;
			break;
		}
		case cUnitTypedeNMPapalElmetto:
		{
			retVal = 3;
			break;
		}
		case cUnitTypedeNMPapalZouave:
		{
			retVal = 4;
			break;
		}
	}

	return (retVal);
}

// AI refuses to train them via tech?
/* rule basilicaMonitor
inactive
minInterval 30
{
	// Maintain plans
	static int basilicaUPID = -1;
	static int basilicaUnitTypes = -1;
	static int basilicaResearchPlans = -1;

	if (cvOkToTrainArmy == false)
		return;

	if (basilicaUnitTypes < 0)
	{
		basilicaUnitTypes = arrayCreateInt(4, "Basilica Papal Unit Types");
		arrayPushInt(basilicaUnitTypes, cUnitTypedePapalGuard);
		arrayPushInt(basilicaUnitTypes, cUnitTypedeNMPandour);
		arrayPushInt(basilicaUnitTypes, cUnitTypedeNMPapalElmetto);
		arrayPushInt(basilicaUnitTypes, cUnitTypedeNMPapalZouave);
		basilicaResearchPlans = arrayCreateInt(1, "Basilica Papal Unit Research Plans.");
	}

	int temp = 4;
	if (kbGetAge() < cAge3)
		temp = 2;
	else if (kbGetAge() < cAge4)
		temp = 3;
	int trainUnitID = -1;
	int techID = -1;
	int papalUnitsPerTech = -1;
	int papalUnitCount = -1;
	int planID = -1;
	int basilicaID = -1;
	int numberToMaintain = 0;
	int popCount = 0;

	for (i = 0; < arrayGetSize(basilicaResearchPlans))
	{
		echoMessage("Basilica Plan " + i + " state: " + aiPlanGetState(arrayGetInt(basilicaResearchPlans, i)));
		echoMessage("Basilica Plan " + i + " active: " + aiPlanGetActive(arrayGetInt(basilicaResearchPlans, i)));
	}

	arrayRemoveDonePlans(basilicaResearchPlans);
	int basilicaQuery = createSimpleUnitQuery(cUnitTypedeBasilica, cMyID, cUnitStateAlive);
	int numberBasilicas = kbUnitQueryExecute(basilicaQuery);
	// Don't proceed until we have a Basilica from which we can train papal units.
	if (numberBasilicas == 0)
		return;

	// Our active research plans do not exceed the number of Basilicas.
	if (arrayGetSize(basilicaResearchPlans) < numberBasilicas)
	{
		// Search for a Basilica that is not being used for a Research plan.
		for (index = 0; < numberBasilicas)
		{
			trainUnitID = arrayGetInt(basilicaUnitTypes, aiRandInt(temp));
			if (trainUnitID < 0)
				continue;
			echoMessage("trainUnitID: " + kbGetUnitTypeName(trainUnitID));
			techID = getBasilicaTechFromPapalUnitType(trainUnitID);
			papalUnitsPerTech = getPapalNumUnitsPerTech(trainUnitID);
			papalUnitCount = kbUnitCount(cMyID, trainUnitID, cUnitStateAlive);

			popCount = kbGetProtoUnitPopCount(trainUnitID);
			numberToMaintain = (0.5 * (1.0 / (temp * 1.0))) * (aiGetMilitaryPop() / popCount);
			echoMessage("numberToMaintain:" + numberToMaintain);
			// We have enough already.
			if (papalUnitCount - numberToMaintain >= 0)
				continue;

			for (i = 0; < numberBasilicas)
			{
				basilicaID = kbUnitQueryGetResult(basilicaQuery, i);
				// Check all the current Papal Research plans.
				for (j = 0; < arrayGetSize(basilicaResearchPlans))
				{
					planID = arrayGetInt(basilicaResearchPlans, j);
					if (basilicaID == aiPlanGetVariableInt(planID, cResearchPlanBuildingID, 0))
					{	// This Basilica is already occupied with a plan.
						basilicaID = -1;
						break;
					}
				}
				if (basilicaID >= 0)
					break;
			}

			if (basilicaID < 0)
			{
				echoMessage("All Basilicas occupied with plans.");
				return;
			}

			echoMessage("Creating research plan.");
			arrayPushInt(basilicaResearchPlans, createResearchPlan(techID, cUnitTypedeBasilica));
		}
	}
} */


//==============================================================================
// Native Monitor
//==============================================================================
rule nativeMonitor
inactive
minInterval 30
{
	static int nativeUPID = -1;
	static int nativeMaintainPlans = -1;
	static int nativeBuildingIDs = -1;

	if (nativeUPID < 0)
	{
		// Create it.
		nativeUPID = kbUnitPickCreate("Native Warrior");
		if (nativeUPID < 0)
			return;

		nativeMaintainPlans = xsArrayCreateInt(3, -1, "Native warrior maintain plans");
		nativeBuildingIDs = xsArrayCreateInt(3, -1, "Native warrior buildings");
	}

	int trainUnitID = -1;
	int planID = -1;
	int numberToMaintain = 0;
	int militaryPopPercentage = 15;
	int buildLimit = 0;
	int upgradeTechID = -1;
	int upgradePlanID = -1;
	float totalValue = 0.0;
	int trainBuildingID = -2;
	int mainBaseID = kbBaseGetMainID(cMyID);
	vector mainBaseLocation = kbBaseGetLocation(cMyID, mainBaseID);
	float mainBaseDist = kbBaseGetDistance(cMyID, mainBaseID);
	int age = kbGetAge();

	// Default init.
	kbUnitPickResetAll(nativeUPID);
	kbUnitPickSetPreferenceWeight(nativeUPID, 1.0);
	kbUnitPickSetCombatEfficiencyWeight(nativeUPID, 0.0);
	kbUnitPickSetBuildingCombatEfficiencyWeight(nativeUPID, 0.0);
	kbUnitPickSetCostWeight(nativeUPID, 0.0);
	// Desired number units types, buildings.
	kbUnitPickSetDesiredNumberUnitTypes(nativeUPID, 3, 1, true);
	kbUnitPickSetEnemyPlayerID(nativeUPID, aiGetMostHatedPlayerID());
	kbUnitPickSetPreferenceFactor(nativeUPID, cUnitTypeAbstractNativeWarrior, 1.0);
	kbUnitPickRun(nativeUPID);

	int numberPlans = xsArrayGetSize(nativeMaintainPlans);
	int numberUnitTypes = kbUnitPickGetNumberResults(nativeUPID);

	if (numberUnitTypes > numberPlans)
	{
		xsArrayResizeInt(nativeMaintainPlans, numberUnitTypes);
		for (i = numberPlans; < numberUnitTypes)
			xsArraySetInt(nativeMaintainPlans, i, -1);
	}

	for (i = 0; < numberUnitTypes)
	{
		trainUnitID = kbUnitPickGetResult(nativeUPID, i);
		planID = xsArrayGetInt(nativeMaintainPlans, i);
		buildLimit = kbGetBuildLimit(cMyID, trainUnitID);
		if (buildLimit == 0)
			trainUnitID = -1;
			
		if (planID >= 0 && trainUnitID != aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0))
		{
			aiPlanDestroy(planID);
			planID = -1;
		}

		if (trainUnitID < 0)
			continue;

		if (planID < 0)
		{
			planID = createSimpleMaintainPlan(trainUnitID, 0, false, mainBaseID, 1);
			xsArraySetInt(nativeMaintainPlans, i, planID);
		}

		if (age <= cAge4)
		{
			// resource equivalent to 0-20% of our military pop
			numberToMaintain = (aiGetMilitaryPop() * militaryPopPercentage) / 
				(kbUnitCostPerResource(trainUnitID, cResourceGold) + 
				 kbUnitCostPerResource(trainUnitID, cResourceWood) + 
				 kbUnitCostPerResource(trainUnitID, cResourceFood));
		}
		else
		{
			numberToMaintain = buildLimit;
		}

		aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, numberToMaintain);

		// Train from main base whenever possible.
		if (numberToMaintain > 0)
		{
			if (trainBuildingID == -2)
			{
				trainBuildingID = getUnitByLocation(cUnitTypeNativeEmbassy, cMyID, cUnitStateAlive, mainBaseLocation, mainBaseDist);
				if (trainBuildingID < 0 && civIsAfrican() == true)
					trainBuildingID = getUnitByLocation(cUnitTypedePalace, cMyID, cUnitStateAlive, mainBaseLocation, mainBaseDist);
			}
			aiPlanSetVariableInt(planID, cTrainPlanBuildingID, 0, trainBuildingID);
		}
		else
		{
			aiPlanSetVariableInt(planID, cTrainPlanBuildingID, 0, -1);
		}

		// create a research plan.
		if (age >= cAge3)
		{
			upgradeTechID = kbTechTreeGetCheapestUnitUpgrade(trainUnitID, cUnitTypeTradingPost);
			if (upgradeTechID >= 0)
			{
				upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, upgradeTechID);

				if (upgradePlanID < 0)
				{
					upgradePlanID = aiPlanCreate("Research " + kbGetTechName(upgradeTechID), cPlanResearch);
					aiPlanSetVariableInt(upgradePlanID, cResearchPlanTechID, 0, upgradeTechID);
					aiPlanSetVariableInt(upgradePlanID, cResearchPlanBuildingTypeID, 0, cUnitTypeTradingPost);
					aiPlanSetActive(upgradePlanID);
					debugMilitary("*** Creating research plan for " + kbGetTechName(upgradeTechID));
				}

				aiPlanSetParentID(upgradePlanID, planID);

				totalValue = 
					kbUnitCostPerResource(trainUnitID, cResourceFood) +
					kbUnitCostPerResource(trainUnitID, cResourceWood) +
					kbUnitCostPerResource(trainUnitID, cResourceGold) +
					kbUnitCostPerResource(trainUnitID, cResourceInfluence);
				totalValue = totalValue * kbUnitCount(cMyID, trainUnitID, cUnitStateABQ);

				// below default priority if we do not have enough units.
				if (totalValue < 800.0)
					aiPlanSetDesiredResourcePriority(upgradePlanID, 45 - (5 - totalValue / 200));
				else
					aiPlanSetDesiredResourcePriority(upgradePlanID, 50);
			}
		}
	}

	for (i = numberUnitTypes; < numberPlans)
	{
		planID = xsArrayGetInt(nativeMaintainPlans, i);
		if (planID >= 0)
		{
			aiPlanDestroy(planID);
			xsArraySetInt(nativeMaintainPlans, i, -1);
		}
	}
}


//==============================================================================
/* Influence Manager
//
// Train units and research techs with influence resource.
*/
//==============================================================================
rule influenceManager
inactive
minInterval 45
{
	// Maintain plans
	static int influenceUPID = -1;
	static int influenceMaintainPlans = -1;

	researchSimpleTech(cTechDEImportedCannons, cUnitTypedePalace);

	if (cvOkToTrainArmy == false)
		return;

	if (influenceUPID < 0)
	{
		// Create it.
		influenceUPID = kbUnitPickCreate("Influence military units");
		if (influenceUPID < 0)
			return;

		influenceMaintainPlans = xsArrayCreateInt(3, -1, "Influence maintain plans");
	}

	int numberResults = 0;
	int i = 0;
	int trainUnitID = -1;
	int planID = -1;
	int numberToMaintain = 0;
	int popCount = 0;
	int buildLimit = 0;
	float totalFactor = 0.0;
	float unitCost = 0.0;

	// Default init.
	kbUnitPickResetAll(influenceUPID);

	// Desired number units types, buildings.
	kbUnitPickSetDesiredNumberUnitTypes(influenceUPID, 2, 1, true);

	setUnitPickerCommon(influenceUPID);

	kbUnitPickSetMinimumCounterModePop(influenceUPID, 15);
	kbUnitPickSetPreferenceFactor(influenceUPID, cUnitTypeMercenary, 1.0);
	kbUnitPickSetPreferenceFactor(influenceUPID, cUnitTypeAbstractNativeWarrior, 1.0);
	kbUnitPickSetPreferenceFactor(influenceUPID, cUnitTypedeMaigadi, 1.0);
	kbUnitPickSetPreferenceFactor(influenceUPID, cUnitTypedeSebastopolMortar, 1.0);
	kbUnitPickSetPreferenceFactor(influenceUPID, cUnitTypeFalconet, 1.0);
	kbUnitPickSetPreferenceFactor(influenceUPID, cUnitTypeOrganGun, 1.0);
	kbUnitPickSetPreferenceFactor(influenceUPID, cUnitTypeCulverin, 1.0);
	kbUnitPickSetPreferenceFactor(influenceUPID, cUnitTypeMortar, 1.0);
	kbUnitPickSetPreferenceFactor(influenceUPID, cUnitTypeypMahout, 1.0);
	kbUnitPickSetPreferenceFactor(influenceUPID, cUnitTypeypHowdah, 1.0);
	kbUnitPickRun(influenceUPID);

	for (i = 0; < 2)
		totalFactor = totalFactor + kbUnitPickGetResultFactor(influenceUPID, i);

	float influenceAmount = kbResourceGet(cResourceInfluence);

	for (i = 0; < 2)
	{
		trainUnitID = kbUnitPickGetResult(influenceUPID, i);
		planID = xsArrayGetInt(influenceMaintainPlans, i);

		if (planID >= 0)
		{
			if (trainUnitID != aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0))
			{
				aiPlanDestroy(planID);
				planID = -1;
			}
		}
		if (trainUnitID < 0)
			continue;

		// if we do not have enough influence for this unit, don't plan training anymore.
		if (influenceAmount > 0.0)
		{
			popCount = kbGetProtoUnitPopCount(trainUnitID);
			unitCost = kbUnitCostPerResource(trainUnitID, cResourceInfluence);
			// hardcoded to at most 40% of our military pop.
			if (popCount > 0)
			{
				numberToMaintain =
					0.4 * (kbUnitPickGetResultFactor(influenceUPID, i) / totalFactor) * aiGetMilitaryPop() / popCount;
			}
			else
			{
				numberToMaintain = 0.4 * (kbUnitPickGetResultFactor(influenceUPID, i) / totalFactor) * aiGetMilitaryPop() /
					(unitCost * 0.01);
			}
			buildLimit = kbGetBuildLimit(cMyID, trainUnitID);
			if (buildLimit > 0 && numberToMaintain > buildLimit)
				numberToMaintain = buildLimit;
			influenceAmount =
				influenceAmount - ((numberToMaintain - kbUnitCount(cMyID, trainUnitID, cUnitStateABQ)) * unitCost);
		}
		else
		{
			numberToMaintain = 0;
		}

		if (planID >= 0)
		{
			aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, numberToMaintain);
		}
		else
		{
			planID = createSimpleMaintainPlan(trainUnitID, numberToMaintain, false, kbBaseGetMainID(cMyID), 1);
			aiPlanSetDesiredResourcePriority(planID, 45 - i); // below research plans
			xsArraySetInt(influenceMaintainPlans, i, planID);
		}
	}
}


//==============================================================================
// defenseReflexPlansReady
// The reflex rule owns two persistent combat plans. Never touch either plan or
// leave the rule enabled unless both IDs still refer to live plans.
//==============================================================================
bool defenseReflexPlansReady(string caller = "defense reflex", bool reportFailure = true)
{
	bool defendPlanReady = true;
	bool reservePlanReady = true;

	if (gLandDefendPlan0 < 0)
	{
		defendPlanReady = false;
	}
	else if (aiPlanGetState(gLandDefendPlan0) < 0)
	{
		gLandDefendPlan0 = -1;
		defendPlanReady = false;
	}
	else if (aiPlanGetType(gLandDefendPlan0) != cPlanCombat ||
		aiPlanGetVariableInt(gLandDefendPlan0, cCombatPlanCombatType, 0) != cCombatPlanCombatTypeDefend)
	{
		gLandDefendPlan0 = -1;
		defendPlanReady = false;
	}
	else if (aiPlanGetActive(gLandDefendPlan0) == false)
	{
		if (aiPlanSetActive(gLandDefendPlan0) == true)
		{
			debugEvent("MIL-REFLEX", caller + ": reactivated persistent land defend plan " +
				gLandDefendPlan0);
		}
		else
		{
			debugEvent("MIL-INVARIANT", caller + ": could not reactivate persistent land defend plan " +
				gLandDefendPlan0 + "; replacing it");
			aiPlanDestroy(gLandDefendPlan0);
			gLandDefendPlan0 = -1;
			defendPlanReady = false;
		}
	}

	if (gLandReservePlan < 0)
	{
		reservePlanReady = false;
	}
	else if (aiPlanGetState(gLandReservePlan) < 0)
	{
		gLandReservePlan = -1;
		reservePlanReady = false;
	}
	else if (aiPlanGetType(gLandReservePlan) != cPlanCombat ||
		aiPlanGetVariableInt(gLandReservePlan, cCombatPlanCombatType, 0) != cCombatPlanCombatTypeDefend)
	{
		gLandReservePlan = -1;
		reservePlanReady = false;
	}
	else if (aiPlanGetActive(gLandReservePlan) == false)
	{
		if (aiPlanSetActive(gLandReservePlan) == true)
		{
			debugEvent("MIL-REFLEX", caller + ": reactivated persistent land reserve plan " +
				gLandReservePlan);
		}
		else
		{
			debugEvent("MIL-INVARIANT", caller + ": could not reactivate persistent land reserve plan " +
				gLandReservePlan + "; replacing it");
			aiPlanDestroy(gLandReservePlan);
			gLandReservePlan = -1;
			reservePlanReady = false;
		}
	}

	if (defendPlanReady == true && reservePlanReady == true)
	{
		return (true);
	}

	xsDisableRule("defenseReflex");
	gDefenseReflex = false;
	gDefenseReflexPaused = false;
	gDefenseReflexBaseID = -1;
	gDefenseReflexLocation = cInvalidVector;
	gDefenseReflexTimeout = 0;
	if (reportFailure == true)
	{
		debugEvent("MIL-INVARIANT", caller + ": persistent defense plan missing; reflex disabled");
	}
	return (false);
}


//==============================================================================
// cancelNonPersistentLandCombatMissions
// A main-base reflex must reclaim land combat units from real attack and
// ally-defense missions. Persistent, specialist, and water plans are preserved.
//==============================================================================
bool isProtectedLandCombatPlan(int planID = -1)
{
	return(
		(planID == gLandDefendPlan0) ||
		(planID == gLandReservePlan) ||
		(planID == gBaseDefendPlan) ||
		(planID == gExplorerControlPlan) ||
		(planID == gHealerPlan) ||
		(planID == gNavyAttackPlan) ||
		(planID == gNavyDefendPlan) ||
		(planID == gNavyRepairPlan));
}


bool isCancelableTopLevelLandCombatPlan(int planID = -1, bool includeAllyDefense = true)
{
	if ((planID < 0) || (aiPlanGetType(planID) != cPlanCombat))
	{
		return(false);
	}
	if (aiPlanGetParentID(planID) >= 0)
	{
		return(false);
	}
	if (isProtectedLandCombatPlan(planID) == true)
	{
		return(false);
	}

	int combatType = aiPlanGetVariableInt(planID, cCombatPlanCombatType, 0);
	if (combatType == cCombatPlanCombatTypeAttack)
	{
		return(true);
	}
	if ((includeAllyDefense == true) && (combatType == cCombatPlanCombatTypeDefend))
	{
		int targetPlayerID = aiPlanGetVariableInt(planID, cCombatPlanTargetPlayerID, 0);
		if ((targetPlayerID > 0) && (targetPlayerID != cMyID) && kbIsPlayerAlly(targetPlayerID))
		{
			return(true);
		}
	}
	return(false);
}


bool cancelTopLevelLandCombatPlan(int planID = -1, string reason = "script",
	bool includeAllyDefense = true)
{
	if ((planID < 0) || (aiPlanGetType(planID) != cPlanCombat))
	{
		return(false);
	}

	int parentPlanID = aiPlanGetParentID(planID);
	if (parentPlanID >= 0)
	{
		debugEvent("MIL-INVARIANT", "refused child combat cancellation id=" + planID +
			" parent=" + parentPlanID + " reason=" + reason);
		return(false);
	}
	if (isCancelableTopLevelLandCombatPlan(planID, includeAllyDefense) == false)
	{
		return(false);
	}

	int combatType = aiPlanGetVariableInt(planID, cCombatPlanCombatType, 0);
	int targetPlayerID = aiPlanGetVariableInt(planID, cCombatPlanTargetPlayerID, 0);
	if ((combatType == cCombatPlanCombatTypeDefend) && (targetPlayerID > 0) &&
		(targetPlayerID != cMyID) && kbIsPlayerAlly(targetPlayerID))
	{
		debugEvent("MIL-HELP", "cancel ally-defense parent=" + planID + " player=" +
			targetPlayerID + " reason=" + reason);
	}
	debugEvent("MIL-MISSION", "cancel parent=" + planID + " combat=" + combatType +
		" reason=" + reason);
	traceTransientLandMissionCancellation(planID, reason);
	aiPlanDestroy(planID);
	return(true);
}


void cancelNonPersistentLandCombatMissions(string reason = "main-base defense reflex",
	bool includeAllyDefense = true)
{
	int planIndex = aiPlanGetActiveCount() - 1;
	int planID = -1;

	// Walk backward so destroying a plan cannot shift an unvisited active-plan index.
	while (planIndex >= 0)
	{
		planID = aiPlanGetIDByActiveIndex(planIndex);
		cancelTopLevelLandCombatPlan(planID, reason, includeAllyDefense);
		planIndex--;
	}
}


//==============================================================================
/*
	moveDefenseReflex(vector, radius, baseID)

	Move the defend and reserve plans to the specified location
	Sets the gLandDefendPlan0 to a high pop count, so it steals units from the reserve plan,
	which will signal the AI to not start new attacks as no reserves are available.
*/
//==============================================================================
void moveDefenseReflex(vector location = cInvalidVector, float radius = -1.0, int baseID = -1)
{
	if (defenseReflexPlansReady("moveDefenseReflex") == false)
	{
		return;
	}

	bool wasActive = gDefenseReflex;
	bool wasPaused = gDefenseReflexPaused;
	int previousBaseID = gDefenseReflexBaseID;

	if (radius < 0.0)
		radius = cvDefenseReflexRadiusActive;
	if (location != cInvalidVector)
	{
		float desiredRadius = radius;

		// radius = calculateDefenseReflexEngageRange(location, radius, 15.0);

		if (baseID < 0 /* || radius < desiredRadius */)
		{
			aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetMode, 0, cCombatPlanTargetModePoint);
			aiPlanSetVariableVector(gLandDefendPlan0, cCombatPlanTargetPoint, 0, location);
			aiPlanSetVariableFloat(gLandDefendPlan0, cCombatPlanTargetEngageRange, 0, radius);
		}
		else
		{
			aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetMode, 0, cCombatPlanTargetModeBase);
			aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetPlayerID, 0, cMyID);
			aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetBaseID, 0, baseID);
			aiPlanSetVariableVector(gLandDefendPlan0, cCombatPlanTargetPoint, 0, location);
		}

		aiPlanSetVariableFloat(gLandDefendPlan0, cCombatPlanGatherDistance, 0, radius - 10.0);
		aiPlanAddUnitType(gLandDefendPlan0, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);

		if (baseID < 0)
		{
			aiPlanSetVariableInt(gLandReservePlan, cCombatPlanTargetMode, 0, cCombatPlanTargetModePoint);
			aiPlanSetVariableVector(gLandReservePlan, cCombatPlanTargetPoint, 0, location);
			aiPlanSetVariableFloat(gLandReservePlan, cCombatPlanTargetEngageRange, 0, radius);
		}
		else
		{
			aiPlanSetVariableInt(gLandReservePlan, cCombatPlanTargetMode, 0, cCombatPlanTargetModeBase);
			aiPlanSetVariableInt(gLandReservePlan, cCombatPlanTargetPlayerID, 0, cMyID);
			aiPlanSetVariableInt(gLandReservePlan, cCombatPlanTargetBaseID, 0, baseID);
			aiPlanSetVariableVector(gLandReservePlan, cCombatPlanTargetPoint, 0, location);
		}

		aiPlanSetVariableFloat(gLandReservePlan, cCombatPlanGatherDistance, 0, radius - 10.0);
		aiPlanAddUnitType(gLandReservePlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 1);

		gDefenseReflex = true;
		gDefenseReflexBaseID = baseID;
		gDefenseReflexLocation = location;
		gDefenseReflexTimeout = xsGetTime() + aiRandInt(300) * 1000;
		gDefenseReflexPaused = false;
	}
	debugMilitary("******** Defense reflex moved to base " + baseID + " with radius " + radius + " and location " + location);
	if (wasActive == false && gDefenseReflex == true)
	{
		debugEvent("MIL-REFLEX", "entered at base " + baseID);
	}
	else if (previousBaseID != baseID)
	{
		debugEvent("MIL-REFLEX", "moved from base " + previousBaseID + " to base " + baseID);
	}
	else if (wasPaused == true && gDefenseReflexPaused == false)
	{
		debugEvent("MIL-REFLEX", "resumed at base " + baseID);
	}
}


//==============================================================================
/*
	pauseDefenseReflex()

	The base (gDefenseReflexBaseID) is still under attack, but we don't have enough
	forces to engage.  Retreat to main base, set a small radius, and wait until we
	have enough troops to re-engage through a moveDefenseReflex() call.
	Sets gLandDefendPlan0 to high troop count to keep reserve plan empty.
	Leaves the base ID and location untouched, even though units will gather at home.
*/
//==============================================================================
void pauseDefenseReflex(void)
{
	if (defenseReflexPlansReady("pauseDefenseReflex") == false)
	{
		return;
	}

	// vector loc = kbBaseGetMilitaryGatherPoint(cMyID, kbBaseGetMainID(cMyID));
	vector loc = (gHomeBase + gDirection_UP * 30.0);
	if (gForwardBaseState != cForwardBaseStateNone)
		loc = gForwardBaseLocation;

	float radius = cvDefenseReflexRadiusActive;

	aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetMode, 0, cCombatPlanTargetModePoint);
	aiPlanSetVariableVector(gLandDefendPlan0, cCombatPlanTargetPoint, 0, loc);
	aiPlanSetVariableFloat(gLandDefendPlan0, cCombatPlanTargetEngageRange, 0, radius);
	aiPlanSetVariableFloat(gLandDefendPlan0, cCombatPlanGatherDistance, 0, radius - 10.0);

	aiPlanSetVariableInt(gLandReservePlan, cCombatPlanTargetMode, 0, cCombatPlanTargetModePoint);
	aiPlanSetVariableVector(gLandReservePlan, cCombatPlanTargetPoint, 0, loc);
	aiPlanSetVariableFloat(gLandReservePlan, cCombatPlanTargetEngageRange, 0, radius);
	aiPlanSetVariableFloat(gLandReservePlan, cCombatPlanGatherDistance, 0, radius - 10.0);
	
	aiPlanAddUnitType(gLandDefendPlan0, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);
	aiPlanAddUnitType(gLandReservePlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 1);

	gDefenseReflexPaused = true;

	debugMilitary("******** Defense reflex paused.");
	debugEvent("MIL-REFLEX", "paused at base " + gDefenseReflexBaseID);
}


//==============================================================================
/*
	endDefenseReflex()

	Move the defend and reserve plans to their default positions
*/
//==============================================================================
void endDefenseReflex(void)
{
	if (defenseReflexPlansReady("endDefenseReflex") == false)
	{
		return;
	}

	int endedBaseID = gDefenseReflexBaseID;
	bool wasActive = gDefenseReflex;
	vector resLoc = kbBaseGetMilitaryGatherPoint(cMyID, kbBaseGetMainID(cMyID));
	int defBaseID = kbBaseGetMainID(cMyID);
	vector defLoc = kbBaseGetLocation(cMyID, defBaseID);

	if (gForwardBaseState != cForwardBaseStateNone && gForwardBaseShouldDefend == true)
	{
		resLoc = gForwardBaseLocation;
		defLoc = gForwardBaseLocation;
		defBaseID = gForwardBaseID;
	}
	// float radius = calculateDefenseReflexEngageRange(defLoc, cvDefenseReflexRadiusActive, 15.0);
	// radius = calculateDefenseReflexEngageRange(defLoc, radius, 15.0);

	float radius = cvDefenseReflexRadiusActive;

	if (radius < cvDefenseReflexRadiusActive)
	{
		aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetMode, 0, cCombatPlanTargetModePoint);
		aiPlanSetVariableVector(gLandDefendPlan0, cCombatPlanTargetPoint, 0, defLoc);
		aiPlanSetVariableFloat(gLandDefendPlan0, cCombatPlanTargetEngageRange, 0, radius);
	}
	else
	{
		aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetMode, 0, cCombatPlanTargetModeBase);
		aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetPlayerID, 0, cMyID);
		aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetBaseID, 0, defBaseID);
		aiPlanSetVariableVector(gLandDefendPlan0, cCombatPlanTargetPoint, 0, defLoc);
	}
	aiPlanAddUnitType(
		gLandDefendPlan0,
		cUnitTypeLogicalTypeLandMilitary,
		0,
		0,
		1); // Defend plan will use 1 unit to defend against stray snipers, etc.

	// radius = calculateDefenseReflexEngageRange(resLoc, cvDefenseReflexRadiusPassive, 15.0);

	aiPlanSetVariableInt(gLandReservePlan, cCombatPlanTargetMode, 0, cCombatPlanTargetModePoint);
	aiPlanSetVariableVector(gLandReservePlan, cCombatPlanTargetPoint, 0, resLoc);
	aiPlanSetVariableFloat(gLandReservePlan, cCombatPlanTargetEngageRange, 0, radius);
	aiPlanSetVariableFloat(gLandReservePlan, cCombatPlanGatherDistance, 0, radius - 10.0);
	aiPlanAddUnitType(gLandReservePlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);   // All unused troops

	debugMilitary("******** Defense reflex terminated for base " + gDefenseReflexBaseID + " at location " + gDefenseReflexLocation);
	debugMilitary("******** Returning to " + resLoc);
	debugMilitary(" Forward base ID is " + gForwardBaseID + ", location is " + gForwardBaseLocation);

	gDefenseReflex = false;
	gDefenseReflexPaused = false;
	gDefenseReflexBaseID = -1;
	gDefenseReflexLocation = cInvalidVector;
	gDefenseReflexTimeout = 0;
	if (wasActive == true)
	{
		debugEvent("MIL-REFLEX", "ended at base " + endedBaseID);
	}
}


// Use this instead of calling endDefenseReflex in the createMainBase function,
// so that the new BaseID will be available.
rule endDefenseReflexDelay
inactive
minInterval 1
{
	xsDisableSelf();
	if (defenseReflexPlansReady("endDefenseReflexDelay") == false)
	{
		return;
	}
	endDefenseReflex();
}


//==============================================================================
/* Defend0

	Create a defend plan, protect the main base.
*/
//==============================================================================
rule defend0
inactive
group postStartup
minInterval 13
{
	int mainBaseID = kbBaseGetMainID(cMyID);
	if (mainBaseID < 0)
	{
		xsDisableRule("defenseReflex");
		gDefenseReflex = false;
		gDefenseReflexPaused = false;
		gDefenseReflexBaseID = -1;
		gDefenseReflexLocation = cInvalidVector;
		gDefenseReflexTimeout = 0;
		debugEvent("MIL-INVARIANT", "defend0: main base is missing; reflex disabled");
		return;
	}

	// Normalize stale plan IDs and disable the consumer while either plan is absent.
	bool reportMissingPlans = xsIsRuleEnabled("defenseReflex") || gDefenseReflex;
	bool plansWereReady = defenseReflexPlansReady("defend0 health check", reportMissingPlans);
	bool repairedPlan = false;
	vector mainBaseLocation = kbBaseGetLocation(cMyID, mainBaseID);
	vector targetPoint = kbBaseGetMilitaryGatherPoint(cMyID, mainBaseID);
	if (mainBaseLocation == cInvalidVector)
	{
		xsDisableRule("defenseReflex");
		gDefenseReflex = false;
		gDefenseReflexPaused = false;
		gDefenseReflexBaseID = -1;
		gDefenseReflexLocation = cInvalidVector;
		gDefenseReflexTimeout = 0;
		debugEvent("MIL-INVARIANT", "defend0: main-base location is invalid; reflex disabled");
		return;
	}
	if (targetPoint == cInvalidVector)
		targetPoint = mainBaseLocation;
	int difficulty = cDifficultyCurrent;

	if (gLandDefendPlan0 < 0)
	{
		gLandDefendPlan0 = aiPlanCreate("Primary Land Defend", cPlanCombat);
		if (gLandDefendPlan0 >= 0)
		{
			aiPlanAddUnitType(gLandDefendPlan0, cUnitTypeLogicalTypeLandMilitary, 0, 0, 1); // Small, until defense reflex.
			aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanCombatType, 0, cCombatPlanCombatTypeDefend);
			aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetMode, 0, cCombatPlanTargetModeBase);
			aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetPlayerID, 0, cMyID);
			aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetBaseID, 0, mainBaseID);
			aiPlanSetVariableVector(gLandDefendPlan0, cCombatPlanTargetPoint, 0, targetPoint);
			aiPlanSetVariableFloat(gLandDefendPlan0, cCombatPlanGatherDistance, 0, 20.0);
			aiPlanSetInitialPosition(gLandDefendPlan0, mainBaseLocation);
			if (difficulty >= cDifficultyHard)
			{
				aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanRefreshFrequency, 0, 300);
				aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanRetreatMode, 0,
					cCombatPlanRetreatModeOutnumbered);
			}
			else
			{
				aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanRefreshFrequency, 0, 1000);
			}
			aiPlanSetDesiredPriority(gLandDefendPlan0, 10); // Very low priority, don't steal from attack plans.
			aiPlanSetActive(gLandDefendPlan0);
			repairedPlan = true;
			debugMilitary("Creating primary land defend plan");
			debugEvent("MIL-MISSION", "created persistent land defend plan " + gLandDefendPlan0);
		}
		else
		{
			debugEvent("MIL-INVARIANT", "defend0: failed to create persistent land defend plan");
		}
	}

	if (gLandReservePlan < 0)
	{
		gLandReservePlan = aiPlanCreate("Land Reserve Units", cPlanCombat);
		if (gLandReservePlan >= 0)
		{
			int reserveTargetMode = cCombatPlanTargetModeBase;
			vector reserveTargetPoint = targetPoint;
			if (reserveTargetPoint == cInvalidVector)
			{
				int aiStartID = getUnit(cUnitTypeAIStart, cMyID);
				if (aiStartID >= 0)
				{
					reserveTargetPoint = kbUnitGetPosition(aiStartID);
					reserveTargetMode = cCombatPlanTargetModePoint;
				}
			}
			if (reserveTargetPoint == cInvalidVector)
			{
				reserveTargetPoint = mainBaseLocation;
			}

			aiPlanAddUnitType(
				gLandReservePlan,
				cUnitTypeLogicalTypeLandMilitary,
				0,
				5,
				200); // All military units, high MAX value to gather unused forces.
			aiPlanSetVariableInt(gLandReservePlan, cCombatPlanCombatType, 0, cCombatPlanCombatTypeDefend);
			aiPlanSetVariableInt(gLandReservePlan, cCombatPlanTargetMode, 0, reserveTargetMode);
			if (reserveTargetMode == cCombatPlanTargetModeBase)
			{
				aiPlanSetVariableInt(gLandReservePlan, cCombatPlanTargetPlayerID, 0, cMyID);
				aiPlanSetVariableInt(gLandReservePlan, cCombatPlanTargetBaseID, 0, mainBaseID);
			}
			else
			{
				aiPlanSetVariableFloat(gLandReservePlan, cCombatPlanTargetEngageRange, 0, 60.0);
			}
			aiPlanSetVariableVector(gLandReservePlan, cCombatPlanTargetPoint, 0, reserveTargetPoint);
			aiPlanSetVariableFloat(gLandReservePlan, cCombatPlanGatherDistance, 0, 20.0);
			aiPlanSetInitialPosition(gLandReservePlan, mainBaseLocation);
			if (difficulty >= cDifficultyHard)
			{
				aiPlanSetVariableInt(gLandReservePlan, cCombatPlanRefreshFrequency, 0, 300);
				aiPlanSetVariableInt(gLandReservePlan, cCombatPlanRetreatMode, 0,
					cCombatPlanRetreatModeOutnumbered);
			}
			else
			{
				aiPlanSetVariableInt(gLandReservePlan, cCombatPlanRefreshFrequency, 0, 1000);
			}
			aiPlanSetDesiredPriority(gLandReservePlan, 5); // Very low priority, gather unused units.
			aiPlanSetActive(gLandReservePlan);
			repairedPlan = true;
			debugMilitary("Creating reserve plan");
			debugEvent("MIL-MISSION", "created persistent land reserve plan " + gLandReservePlan);
		}
		else
		{
			debugEvent("MIL-INVARIANT", "defend0: failed to create persistent land reserve plan");
		}
	}

	if (defenseReflexPlansReady("defend0 post-repair") == true)
	{
		// Repair a valid but inactive persistent plan before the reflex rule can consume it.
		aiPlanSetActive(gLandDefendPlan0);
		aiPlanSetActive(gLandReservePlan);
		if (repairedPlan == true)
		{
			// Restore passive targets after both replacement plans have been created.
			xsEnableRule("endDefenseReflexDelay");
		}
		if (xsIsRuleEnabled("defenseReflex") == false)
		{
			debugEvent("MIL-REFLEX", "enabled with defend/reserve plans ready");
		}
		xsEnableRule("defenseReflex");
	}
	else
	{
		xsDisableRule("defenseReflex");
		if (plansWereReady == true)
		{
			debugEvent("MIL-INVARIANT", "defend0: defense plans became unavailable");
		}
	}
}


rule baseDefenseForce
inactive
minInterval 20
{
	int numMilitaryUnits = kbUnitCount(cMyID, cUnitTypeAbstractInfantry, cUnitStateAlive);
	int numSpecificUnit = -1;
	if (gBaseDefendPlan < 0)
	{
		gBaseDefendPlan = aiPlanCreate("Main Base Combat (Defend) Plan", cPlanCombat);
		aiPlanAddUnitType(gBaseDefendPlan, cUnitTypeAbstractInfantry, 1, numMilitaryUnits / 4, 20);
		aiPlanSetVariableInt(gBaseDefendPlan, cCombatPlanCombatType, 0, cCombatPlanCombatTypeDefend);
		aiPlanSetVariableInt(gBaseDefendPlan, cCombatPlanTargetMode, 0, cCombatPlanTargetModeBase);
		aiPlanSetVariableInt(gBaseDefendPlan, cCombatPlanTargetPlayerID, 0, cMyID);
		aiPlanSetVariableInt(gBaseDefendPlan, cCombatPlanTargetBaseID, 0, gMainBase);
		aiPlanSetVariableVector(gBaseDefendPlan, cCombatPlanTargetPoint, 0, gHomeBase + gDirection_UP * 20.0);
		aiPlanSetVariableFloat(gBaseDefendPlan, cCombatPlanGatherDistance, 0, 20.0);
		aiPlanSetInitialPosition(gBaseDefendPlan, gHomeBase);
		aiPlanSetVariableInt(gBaseDefendPlan, cCombatPlanRefreshFrequency, 0, 300);
		aiPlanSetVariableInt(gBaseDefendPlan, cCombatPlanRetreatMode, 0, cCombatPlanRetreatModeNone);
		aiPlanSetDesiredPriority(gBaseDefendPlan, 60);
		aiPlanSetActive(gBaseDefendPlan);

		/* aiPlanAddUnitType(gBaseDefendPlan, cUnitTypeAbstractInfantry, 1, numMilitaryUnits / 4, 20);
		aiPlanSetVariableVector(gBaseDefendPlan, cDefendPlanDefendPoint, 0, gHomeBase + gDirection_UP * 30.0);
		aiPlanSetVariableInt(gBaseDefendPlan, cDefendPlanDefendBaseID, 0, kbBaseGetMainID(cMyID));
		aiPlanSetVariableFloat(gBaseDefendPlan, cDefendPlanEngageRange, 0, 40.0);
		aiPlanSetInitialPosition(gBaseDefendPlan, gHomeBase);
		aiPlanSetVariableInt(gBaseDefendPlan, cDefendPlanRefreshFrequency, 0, 300);
		aiPlanSetVariableInt(gBaseDefendPlan, cDefendPlanAttackTypeID, 0, cUnitTypeUnit); // Only units
		aiPlanSetDesiredPriority(gBaseDefendPlan, 60);
		aiPlanSetActive(gBaseDefendPlan); */

		debugMilitary("Creating primary Land Combat (Defend) plan.");
	}
	else
	{
		// aiPlanSetVariableFloat(gBaseDefendPlan, cDefendPlanEngageRange, 0, 40.0 + 10.0 * kbGetAge());
		aiPlanSetVariableVector(gBaseDefendPlan, cCombatPlanTargetPoint, 0, gHomeBase + gDirection_UP * (10.0 + 8.0 * kbGetAge()));
		aiPlanAddUnitType(gBaseDefendPlan, cUnitTypeAbstractInfantry, 1, numMilitaryUnits / 4, 20);
		numSpecificUnit = kbUnitCount(cMyID, cUnitTypeMinuteman, cUnitStateAlive);
		aiPlanAddUnitType(gBaseDefendPlan, cUnitTypeMinuteman, numSpecificUnit, numSpecificUnit, numSpecificUnit * 2, true, true);
		numSpecificUnit = kbUnitCount(cMyID, cUnitTypeypIrregular, cUnitStateAlive);
		aiPlanAddUnitType(gBaseDefendPlan, cUnitTypeypIrregular, numSpecificUnit, numSpecificUnit, numSpecificUnit * 2, true, true);
		numSpecificUnit = kbUnitCount(cMyID, cUnitTypeypPeasant, cUnitStateAlive);
		aiPlanAddUnitType(gBaseDefendPlan, cUnitTypeypPeasant, numSpecificUnit, numSpecificUnit, numSpecificUnit * 2, true, true);
		numSpecificUnit = kbUnitCount(cMyID, cUnitTypexpWarrior, cUnitStateAlive);
		aiPlanAddUnitType(gBaseDefendPlan, cUnitTypexpWarrior, numSpecificUnit, numSpecificUnit, numSpecificUnit * 2, true, true);
		numSpecificUnit = kbUnitCount(cMyID, cUnitTypedeSpearmanLevy, cUnitStateAlive);
		aiPlanAddUnitType(gBaseDefendPlan, cUnitTypedeSpearmanLevy, numSpecificUnit, numSpecificUnit, numSpecificUnit * 2, true, true);
		numSpecificUnit = kbUnitCount(cMyID, cUnitTypedeBowmanLevy, cUnitStateAlive);
		aiPlanAddUnitType(gBaseDefendPlan, cUnitTypedeBowmanLevy, numSpecificUnit, numSpecificUnit, numSpecificUnit * 2, true, true);
		numSpecificUnit = kbUnitCount(cMyID, cUnitTypedeGunnerLevy, cUnitStateAlive);
		aiPlanAddUnitType(gBaseDefendPlan, cUnitTypedeGunnerLevy, numSpecificUnit, numSpecificUnit, numSpecificUnit * 2, true, true);
	}
}


//==============================================================================
/* rule defenseReflex

   Monitor each VP site that we own, plus our main base. Move and reconfigure
   the defense and reserve plans as needed.

   At rest, the defend plan has only one unit, is centered on the main base, and
   is used to send one unit after trivial invasions, typically a scouting unit.
   The reserve plan has a much larger MAX number, so it gets all the remaining units.
   It is centered on the military gather point with a conservative radius, to avoid
   engaging units far in front of the main base.

   When defending a base in a defense reflex, the defend plan gets a high MAX number
   so that it takes units from the reserve plan.  The low unit count in reserve
   acts as a signal to not launch new attacks, as troops aren't available.  The
   defend plan and reserve plan are relocated to the endangered base, with an aggressive
   engage radius.

   The search, active engage and passive engage radii are set by global
   control variables, cvDefenseReflexRadiusActive, cvDefenseReflexRadiusPassive, and
   cvDefenseReflexSearchRadius.

   Once in a defense reflex, the AI stays in it until that base is cleared, unless
   it's defending a non-main base, and the main base requires defense.  In that case,
   the defense reflex moves back to the main base.

   pauseDefenseReflex() can only be used when already in a defense reflex.  So valid
   state transitions are:

   none to defending       // start reflex with moveDefenseReflex(), sets all the base/location globals.
   defending to paused     // use pauseDefenseReflex(), takes no parms, uses vars set in prior moveDefenseReflex call.
   defending to end        // use endDefenseReflex(), clears global vars.
   paused to end           // use endDefenseReflex(), clears global vars.
   paused to defending     // use moveDefenseReflex(), set global vars again.

*/
//==============================================================================
rule defenseReflex
inactive
minInterval 10
{
	if (defenseReflexPlansReady("defenseReflex rule") == false)
	{
		return;
	}

	int armySize = aiPlanGetNumberUnits(gLandDefendPlan0, cUnitTypeLogicalTypeLandMilitary) +
					aiPlanGetNumberUnits(gLandReservePlan, cUnitTypeLogicalTypeLandMilitary);
	int enemyArmySize = -1;
	static int lastHelpTime = -60000;
	static int lastHelpBaseID = -1;
	static int lastHelpSuppressedLogTime = -60000;
	int i = 0;
	int unitID = -1;
	int protoUnitID = -1;
	bool panic = false; // Indicates need for call for help.
	string helpSuppressionReason = "";
	int planID = -1;
	int mainBaseID = kbBaseGetMainID(cMyID);
	int time = xsGetTime();

	static int enemyArmyQuery = -1;
	if (enemyArmyQuery < 0) // First run.
	{
		enemyArmyQuery = kbUnitQueryCreate("Enemy army query");
		kbUnitQuerySetIgnoreKnockedOutUnits(enemyArmyQuery, true);
		kbUnitQuerySetPlayerRelation(enemyArmyQuery, cPlayerRelationEnemyNotGaia);
		kbUnitQuerySetUnitType(enemyArmyQuery, cUnitTypeLogicalTypeLandMilitary);
		kbUnitQuerySetState(enemyArmyQuery, cUnitStateAlive);
		kbUnitQuerySetSeeableOnly(enemyArmyQuery, true); // Ignore units we think are under fog.
	}

	// Check main base first.
	kbUnitQuerySetPosition(enemyArmyQuery, kbBaseGetLocation(cMyID, mainBaseID));
	kbUnitQuerySetMaximumDistance(enemyArmyQuery, cvDefenseReflexSearchRadius);
	kbUnitQuerySetSeeableOnly(enemyArmyQuery, true);
	kbUnitQuerySetState(enemyArmyQuery, cUnitStateAlive);
	kbUnitQueryResetResults(enemyArmyQuery);
	enemyArmySize = kbUnitQueryExecute(enemyArmyQuery);
	// Bump up by 1 to just avoid running into this when the enemy explorer and its companion get in our base...
	if (enemyArmySize >= 3)
	{ // Main base is under attack.
		debugMilitary("******** Main base (" + mainBaseID + ") under attack.");
		debugMilitary("******** Enemy count " + enemyArmySize + ", my army count " + armySize);
		if (gDefenseReflexBaseID == mainBaseID)
		{ // We're already in a defense reflex for the main base.
			if (((armySize * 3.0) < enemyArmySize) &&
				(enemyArmySize > 6.0)) // Army at least 3x my size and more than 6 units total.
			{	// Too big to handle.
				if ((gDefenseReflexPaused == false) && (kbUnitCount(cMyID, cUnitTypeMinuteman, cUnitStateAlive) < 1) &&
					(kbUnitCount(cMyID, cUnitTypeypIrregular, cUnitStateAlive) < 1) &&
					(kbUnitCount(cMyID, cUnitTypeypPeasant, cUnitStateAlive) < 1) &&
					(kbUnitCount(cMyID, cUnitTypexpWarrior, cUnitStateAlive) < 2))
				{ // We weren't paused and don't have emergency soldiers with decaying health, do it.
					pauseDefenseReflex();
				}
				// Consider a call for help.
				panic = true;
				if (((time - lastHelpTime) < 300000) &&
					(lastHelpBaseID == gDefenseReflexBaseID)) // We called for help in the last five minutes, and it was this base.
				{
					panic = false;
					helpSuppressionReason = "same-base five-minute cooldown";
				}
				if (((time - lastHelpTime) < 60000) &&
					(lastHelpBaseID != gDefenseReflexBaseID)) // We called for help anywhere in the last minute.
				{
					panic = false;
					helpSuppressionReason = "global one-minute cooldown";
				}

				if (panic == true)
				{
					debugEvent("MIL-HELP", "send request base=" + gDefenseReflexBaseID +
						", army=" + armySize + ", enemy=" + enemyArmySize + ", location=" +
						kbBaseGetLocation(cMyID, gDefenseReflexBaseID));
					sendStatement(cPlayerRelationAllyExcludingSelf, cAICommPromptToAllyINeedHelpMyBase,
						kbBaseGetLocation(cMyID, gDefenseReflexBaseID));
					debugMilitary("I'm calling for help");
					lastHelpTime = time;
					lastHelpBaseID = gDefenseReflexBaseID;
				}
				else if ((time - lastHelpSuppressedLogTime) >= 60000)
				{
					debugEvent("MIL-HELP", "suppress request base=" + gDefenseReflexBaseID +
						": " + helpSuppressionReason + ", elapsedSinceLast=" + (time - lastHelpTime));
					lastHelpSuppressedLogTime = time;
				}

				cancelNonPersistentLandCombatMissions("main-base defense reflex remains outnumbered");
			}
			else
			{	// Size is OK to handle, shouldn't be in paused mode.
				if (gDefenseReflexPaused == true) // Need to turn it active.
				{
					moveDefenseReflex(kbBaseGetLocation(cMyID, mainBaseID), cvDefenseReflexRadiusActive, mainBaseID);
				}
			}
		}
		else // Defense reflex wasn't set to main base.
		{	// Need to set the defense reflex to home base...doesn't matter if it was inactive or guarding another base,
			// home base trumps all.
			// Cancel real land missions before the persistent plans reclaim their units.
			cancelNonPersistentLandCombatMissions("main-base raid");
			moveDefenseReflex(kbBaseGetLocation(cMyID, mainBaseID), cvDefenseReflexRadiusActive, mainBaseID);
			// This is a new defense reflex in the main base.  Consider making a chat about it.
			int enemyPlayerID = kbUnitGetPlayerID(kbUnitQueryGetResult(enemyArmyQuery, 0));
			if ((enemyPlayerID > 0) && (kbGetAge() > cAge1))
			{ // Consider sending a chat as long as we're out of age 1.
				int enemyPlayerUnitCount = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, enemyPlayerID,
				cUnitStateAlive, kbBaseGetLocation(cMyID, gDefenseReflexBaseID), 50.0);
				if (enemyPlayerUnitCount > (2 * gGoodArmyPop) && enemyPlayerUnitCount > (3 * armySize))
				{ // Enemy army is big, and we're badly outnumbered.
					sendStatement(enemyPlayerID, cAICommPromptToEnemyISpotHisArmyMyBaseOverrun, kbBaseGetLocation(cMyID, gDefenseReflexBaseID));
					debugMilitary("Sending OVERRUN prompt to player " + enemyPlayerID + ", he has " + enemyPlayerUnitCount + " units.");
					debugMilitary("I have " + armySize + " units, and " + gGoodArmyPop + " is a good army size.");
					return;
				}
				if (enemyPlayerUnitCount > (2 * gGoodArmyPop))
				{ // Big army, but I'm still in the fight.
					sendStatement(enemyPlayerID, cAICommPromptToEnemyISpotHisArmyMyBaseLarge, kbBaseGetLocation(cMyID, gDefenseReflexBaseID));
					debugMilitary("Sending LARGE ARMY prompt to player " + enemyPlayerID + ", he has " + enemyPlayerUnitCount + " units.");
					debugMilitary("I have " + armySize + " units, and " + gGoodArmyPop + " is a good army size.");
					return;
				}
				if (enemyPlayerUnitCount > gGoodArmyPop)
				{ // Moderate size.
					sendStatement(enemyPlayerID, cAICommPromptToEnemyISpotHisArmyMyBaseMedium, kbBaseGetLocation(cMyID, gDefenseReflexBaseID));
					debugMilitary("Sending MEDIUM ARMY prompt to player " + enemyPlayerID + ", he has " + enemyPlayerUnitCount + " units.");
					debugMilitary("I have " + armySize + " units, and " + gGoodArmyPop + " is a good army size.");
					return;
				}
				if ((enemyPlayerUnitCount < gGoodArmyPop) && (enemyPlayerUnitCount < armySize))
				{ // Small, and under control.
					sendStatement(enemyPlayerID, cAICommPromptToEnemyISpotHisArmyMyBaseSmall, kbBaseGetLocation(cMyID, gDefenseReflexBaseID));
					debugMilitary("Sending SMALL ARMY prompt to player " + enemyPlayerID + ", he has " + enemyPlayerUnitCount + " units.");
					debugMilitary("I have " + armySize + " units, and " + gGoodArmyPop + " is a good army size.");
					return;
				}
			}
		}
		return; // Do not check other bases.
	}

	// If we're this far, the main base is OK.  If we're in a defense reflex, see if we should stay in it, or change from
	// passive to active.

	if (gDefenseReflex == true) // Currently in a defense mode, let's see if it should remain
	{
		kbUnitQuerySetPosition(enemyArmyQuery, gDefenseReflexLocation);
		kbUnitQuerySetMaximumDistance(enemyArmyQuery, cvDefenseReflexSearchRadius);
		kbUnitQuerySetSeeableOnly(enemyArmyQuery, true);
		kbUnitQuerySetState(enemyArmyQuery, cUnitStateAlive);
		kbUnitQueryResetResults(enemyArmyQuery);
		enemyArmySize = kbUnitQueryExecute(enemyArmyQuery);
		debugMilitary("******** Defense reflex in base " + gDefenseReflexBaseID + " at " + gDefenseReflexLocation);
		debugMilitary("******** Enemy unit count: " + enemyArmySize + ", my unit count (defend+reserve) = " + armySize);
		for (i = 0; < enemyArmySize)
		{
			unitID = kbUnitQueryGetResult(enemyArmyQuery, i);
			protoUnitID = kbUnitGetProtoUnitID(unitID);
			if (i < 2)
			{
				debugMilitary("    " + unitID + " " + kbGetProtoUnitName(protoUnitID) + " " + kbUnitGetPosition(unitID));
			}
		}

		if (enemyArmySize < 2)
		{ // Abort, no enemies, or just one scouting unit.
			if (time >= gDefenseReflexTimeout || armySize >= gGoodArmyPop ||
				(gRevolutionType & cRevolutionFinland) == cRevolutionFinland)
			{ // Wait for a random period before moving to the forward base.
				debugMilitary("******** Ending defense reflex, no enemies remain.");
				endDefenseReflex();
			}
			return;
		}

		if (baseBuildingCount(gDefenseReflexBaseID, cPlayerRelationAlly, cUnitStateAlive) <= 0)
		{ // Abort, no alive ally buildings.
			debugMilitary("******** Ending defense reflex, base " + gDefenseReflexBaseID + " has no buildings.");
			endDefenseReflex();
			return;
		}

		if (kbBaseGetOwner(gDefenseReflexBaseID) <= 0)
		{ // Abort, base doesn't exist.
			debugMilitary("******** Ending defense reflex, base " + gDefenseReflexBaseID + " doesn't exist.");
			endDefenseReflex();
			return;
		}

		// The defense reflex for this base should remain in effect.
		// Check whether to start/end paused mode.
		int unitsNeeded = gGoodArmyPop;	// At least a credible army to fight them
		if (unitsNeeded > (enemyArmySize / 2))	// Or half their force, whichever is less.
		{
			unitsNeeded = enemyArmySize / 2;
		}
		bool shouldPause = false;
		if (((armySize < unitsNeeded) && ((armySize * 3.0) < enemyArmySize)) &&
			(kbUnitCount(cMyID, cUnitTypeMinuteman, cUnitStateAlive) < 1) &&
			(kbUnitCount(cMyID, cUnitTypeypIrregular, cUnitStateAlive) < 1) &&
			(kbUnitCount(cMyID, cUnitTypeypPeasant, cUnitStateAlive) < 1) &&
			(kbUnitCount(cMyID, cUnitTypexpWarrior, cUnitStateAlive) < 2))
		{
			shouldPause = true; // We should pause if not paused, or stay paused if we are.
		}

		if (gDefenseReflexPaused == false)
		{ // Not currently paused, do it.
			if (shouldPause == true)
			{
				pauseDefenseReflex();
				debugMilitary("******** Enemy count " + enemyArmySize + ", my army count " + armySize);
			}
		}
		else
		{ // Currently paused...should we remain paused, or go active?
			if (shouldPause == false)
			{
				moveDefenseReflex(gDefenseReflexLocation, cvDefenseReflexRadiusActive, gDefenseReflexBaseID); // Activate it
				debugMilitary("******** Enemy count " + enemyArmySize + ", my army count " + armySize);
			}
		}
		if (shouldPause == true)
		{ // Consider a call for help.
			panic = true;
			if (((time - lastHelpTime) < 300000) &&
				(lastHelpBaseID == gDefenseReflexBaseID)) // We called for help in the last five minutes, and it was this base.
			{
				panic = false;
				helpSuppressionReason = "same-base five-minute cooldown";
			}
			if (((time - lastHelpTime) < 60000) &&
				(lastHelpBaseID != gDefenseReflexBaseID)) // We called for help anywhere in the last minute.
			{
				panic = false;
				helpSuppressionReason = "global one-minute cooldown";
			}

			if (panic == true)
			{
				debugEvent("MIL-HELP", "send request base=" + gDefenseReflexBaseID +
					", army=" + armySize + ", enemy=" + enemyArmySize + ", location=" +
					kbBaseGetLocation(cMyID, gDefenseReflexBaseID));
				sendStatement(cPlayerRelationAlly, cAICommPromptToAllyINeedHelpMyBase, kbBaseGetLocation(cMyID, gDefenseReflexBaseID));
				debugMilitary("     I'm calling for help.");
				lastHelpTime = time;
				lastHelpBaseID = gDefenseReflexBaseID;
			}
			else if ((time - lastHelpSuppressedLogTime) >= 60000)
			{
				debugEvent("MIL-HELP", "suppress request base=" + gDefenseReflexBaseID +
					": " + helpSuppressionReason + ", elapsedSinceLast=" + (time - lastHelpTime));
				lastHelpSuppressedLogTime = time;
			}

			// Call back our attack if any.
			// TODO: Not main base, maybe not always worth defending?
			cancelNonPersistentLandCombatMissions("outnumbered defense reflex", false);
		}
		return; // Done...we're staying in defense mode for this base, and have paused or gone active as needed.
	}

	// Not in a defense reflex, see if one is needed.

	// Check other bases
	int baseCount = -1;
	int baseIndex = -1;
	int baseID = -1;
	vector baseLoc = cInvalidVector;

	baseCount = kbBaseGetNumber(cMyID);
	unitsNeeded = gGoodArmyPop / 2;
	if (baseCount > 0)
	{
		for (baseIndex = 0; < baseCount)
		{
			baseID = kbBaseGetIDByIndex(cMyID, baseIndex);
			if (baseID == kbBaseGetMainID(cMyID))
			{
				continue; // Already checked main at top of function.
			}

			if (baseBuildingCount(baseID, cPlayerRelationAlly, cUnitStateAlive) <= 0)
			{
				debugMilitary("Base " + baseID + " has no alive buildings.");
				continue; // Skip bases that have no buildings.
			}

			// Check for overrun base.
			baseLoc = kbBaseGetLocation(cMyID, baseID);
			kbUnitQuerySetPosition(enemyArmyQuery, baseLoc);
			kbUnitQuerySetMaximumDistance(enemyArmyQuery, cvDefenseReflexSearchRadius);
			kbUnitQuerySetSeeableOnly(enemyArmyQuery, true);
			kbUnitQuerySetState(enemyArmyQuery, cUnitStateAlive);
			kbUnitQueryResetResults(enemyArmyQuery);
			enemyArmySize = kbUnitQueryExecute(enemyArmyQuery);
			// Do I need to call for help?

			if ((enemyArmySize >= 2))
			{ // More than just a scout...set defense reflex for this base.
				moveDefenseReflex(baseLoc, cvDefenseReflexRadiusActive, baseID);

				debugMilitary("******** Enemy count is " + enemyArmySize + ", my army size is " + armySize);

				if ((enemyArmySize > (armySize * 2.0)) && (enemyArmySize > 6)) // Double my size, get help...
				{
					panic = true;
					if (((time - lastHelpTime) < 300000) &&
						(lastHelpBaseID == baseID)) // We called for help in the last five minutes, and it was this base.
					{
						panic = false;
						helpSuppressionReason = "same-base five-minute cooldown";
					}
					if (((time - lastHelpTime) < 60000) &&
						(lastHelpBaseID != baseID)) // We called for help anywhere in the last minute.
					{
						panic = false;
						helpSuppressionReason = "global one-minute cooldown";
					}

					if (panic == true)
					{
						// Don't kill other missions, this isn't the main base. Just call for help.
						debugEvent("MIL-HELP", "send request base=" + baseID + ", army=" + armySize +
							", enemy=" + enemyArmySize + ", location=" + kbBaseGetLocation(cMyID, baseID));
						sendStatement(cPlayerRelationAllyExcludingSelf, cAICommPromptToAllyINeedHelpMyBase,
							kbBaseGetLocation(cMyID, baseID));
						debugMilitary("I'm calling for help.");
						lastHelpTime = time;
						lastHelpBaseID = baseID;
					}
					else if ((time - lastHelpSuppressedLogTime) >= 60000)
					{
						debugEvent("MIL-HELP", "suppress request base=" + baseID + ": " +
							helpSuppressionReason + ", elapsedSinceLast=" + (time - lastHelpTime));
						lastHelpSuppressedLogTime = time;
					}
				}
				else
				{
					moveDefenseReflex(baseLoc, cvDefenseReflexRadiusActive, baseID);
				}
				return; // If we're in trouble in any base, ignore the others.
			}
		} // For baseIndex...
	}
}

//==============================================================================
// Levy Functions
//==============================================================================
rule useLevy
inactive
minInterval 10
{
	static int arrayID = -1;
	if (arrayID == -1) // First run.
	{
		arrayID = arrayCreateInt(1, "Levy Plans");
	}

	int tcQueryID = createSimpleUnitQuery(cUnitTypeAgeUpBuilding, cMyID, cUnitStateAlive);
	int numberResults = kbUnitQueryExecute(tcQueryID);
	int townCenterID = -1;
	int techID = -1;

	arraySetNumElements(arrayID, numberResults, true);

	if (cMyCiv == cCivDEAmericans)
		techID = cTechDEUSLevy;
	else if (cMyCiv == cCivDEHausa)
	{
		if (kbResourceGet(cResourceInfluence) < 1000.0)
			return; // If we do not have excess influence then do not consider this.
		techID = cTechDEAllegianceSonghaiLevyRaiders;
	}
	else
		techID = cTechLevy;
	vector tcLocation = cInvalidVector;
	int allyCount = -1;
	int enemyCount = -1;
	int levyPlan = -1;
	int numberLevyPlans = aiPlanGetNumberByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, techID);
	for (i = 0; < numberLevyPlans)
	{
		levyPlan = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, techID, true, i);
		for (j = 0; < numberResults)
		{
			townCenterID = kbUnitQueryGetResult(tcQueryID, j);
			if (townCenterID == aiPlanGetVariableInt(levyPlan, cResearchPlanBuildingID, 0))
			{
				arraySetInt(arrayID, j, levyPlan);
			}
		}
	}
	
	for (i = 0; < numberResults)
	{
		townCenterID = kbUnitQueryGetResult(tcQueryID, i);
		levyPlan = arrayGetInt(arrayID, i);
		if (kbBuildingTechGetStatus(techID, townCenterID) == cTechStatusObtainable) // TC can still use Levy.
		{

			tcLocation = kbUnitGetPosition(townCenterID);
			enemyCount = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary,
				cPlayerRelationEnemyNotGaia, cUnitStateAlive, tcLocation, 40.0);
			allyCount = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary,
				cPlayerRelationAlly, cUnitStateAlive, tcLocation, 40.0);

			if (enemyCount >= allyCount + 5) // We're behind by 5 or more.
			{
				if ((levyPlan < 0) && ((cMyCiv != cCivDEAmericans) || (numberLevyPlans < 1)))
				{
					debugMilitary("Starting a levy plan, there are " + enemyCount +
						" enemy units in my base against " + allyCount + " friendlies");
					createSimpleResearchPlanSpecificBuilding(techID, townCenterID, cMilitaryEscrowID, 99, 99);
					if (cMyCiv == cCivDEAmericans || cMyCiv == cCivDEHausa)
					{
						return; // We made one plan and shouldn't make more because of the global cooldown.
					}
				}
			}
			else // No need to call levy.
			{
				if (levyPlan >= 0) // We have a plan we must maybe destroy.
				{
					if (townCenterID == aiPlanGetVariableInt(levyPlan, cResearchPlanBuildingID, 0))
					{
						debugMilitary("Destroying levy plan because we're not outnumbered anymore");
						aiPlanDestroy(levyPlan);
					}
				}
			}
		}
	}
}

//==============================================================================
// useWarParties
//==============================================================================
rule useWarParties
inactive
minInterval 10
{
	static int partyPlan = -1; // Save the ID of the plan so we can potentially cancel it.

	int scoutingPartyStatus = -1;
	int raidingPartyStatus = -1;
	int warPartyStatus = -1;
	if (cMyCiv == cCivXPAztec)
	{
		scoutingPartyStatus = kbTechGetStatus(cTechBigAztecScoutingParty);
		raidingPartyStatus = kbTechGetStatus(cTechBigAztecRaidingParty);
		warPartyStatus = kbTechGetStatus(cTechBigAztecWarParty);
	}
	else if (cMyCiv == cCivXPIroquois)
	{
		scoutingPartyStatus = kbTechGetStatus(cTechBigIroquoisScoutingParty);
		raidingPartyStatus = kbTechGetStatus(cTechBigIroquoisRaidingParty);
		warPartyStatus = kbTechGetStatus(cTechBigIroquoisWarParty);
	}
	else if (cMyCiv == cCivDEInca)
	{
		scoutingPartyStatus = kbTechGetStatus(cTechdeBigIncaScoutingParty);
		raidingPartyStatus = kbTechGetStatus(cTechdeBigIncaRaidingParty);
		warPartyStatus = kbTechGetStatus(cTechdeBigIncaWarParty);
	}

	if ((scoutingPartyStatus == cTechStatusActive) &&
		(raidingPartyStatus == cTechStatusActive) && 
		(warPartyStatus == cTechStatusActive))
	{
		xsDisableSelf();
	}

	vector mainBaseVec = kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID));
	int townCenterID = getClosestUnit(cUnitTypeTownCenter, cMyID, cUnitStateAlive, mainBaseVec, 40.0);
	if (townCenterID < 0)
	{
		return; // Can't use war parties if no Town Center alive in the area we're scanning for enemies.
	}
	int enemyCount = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia,
		cUnitStateAlive, mainBaseVec, 40.0);
	int allyCount = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationAlly,
		cUnitStateAlive, mainBaseVec, 40.0);
	

	if (partyPlan < 0) // No plan, see if we need one.
	{
		if (enemyCount >= allyCount + 5) // We're behind by 5 or more.
		{
			debugMilitary("Starting a WarParty plan, there are: " + enemyCount + " enemies in my base against: "
				+ allyCount + " friendlies");

			if (cMyCiv == cCivXPAztec)
			{
				if (scoutingPartyStatus == cTechStatusObtainable)
				{
					partyPlan = createSimpleResearchPlanSpecificBuilding(cTechBigAztecScoutingParty, townCenterID,
						cMilitaryEscrowID, 99); 
				}
				else if (raidingPartyStatus == cTechStatusObtainable)
				{
					partyPlan = createSimpleResearchPlanSpecificBuilding(cTechBigAztecRaidingParty, townCenterID,
						cMilitaryEscrowID, 99);
				}
				else if (warPartyStatus == cTechStatusObtainable)
				{
					partyPlan = createSimpleResearchPlanSpecificBuilding(cTechBigAztecWarParty, townCenterID,
						cMilitaryEscrowID, 99);
				}
			}
			else if (cMyCiv == cCivXPIroquois)
			{
				if (scoutingPartyStatus == cTechStatusObtainable)
				{
					partyPlan = createSimpleResearchPlanSpecificBuilding(cTechBigIroquoisScoutingParty, townCenterID,
						cMilitaryEscrowID, 99); 
				}
				else if (raidingPartyStatus == cTechStatusObtainable)
				{
					partyPlan = createSimpleResearchPlanSpecificBuilding(cTechBigIroquoisRaidingParty, townCenterID,
						cMilitaryEscrowID, 99);
				}
				else if (warPartyStatus == cTechStatusObtainable)
				{
					partyPlan = createSimpleResearchPlanSpecificBuilding(cTechBigIroquoisWarParty, townCenterID,
						cMilitaryEscrowID, 99);
				}
			}
			else if (cMyCiv == cCivDEInca)
			{
				if (scoutingPartyStatus == cTechStatusObtainable)
				{
					partyPlan = createSimpleResearchPlanSpecificBuilding(cTechdeBigIncaScoutingParty, townCenterID,
						cMilitaryEscrowID, 99); 
				}
				else if (raidingPartyStatus == cTechStatusObtainable)
				{
					partyPlan = createSimpleResearchPlanSpecificBuilding(cTechdeBigIncaRaidingParty, townCenterID,
						cMilitaryEscrowID, 99);
				}
				else if (warPartyStatus == cTechStatusObtainable)
				{
					partyPlan = createSimpleResearchPlanSpecificBuilding(cTechdeBigIncaWarParty, townCenterID,
						cMilitaryEscrowID, 99);
				}
			}
		}
	}
	else // Plan exists, make sure it's still needed.
	{
		if ((enemyCount >= allyCount + 2) && (aiPlanGetState(partyPlan) >= 0))
		{	// Do nothing.
			debugMilitary("We're still under attack and waiting for WarParty");
		}
		else
		{
			debugMilitary("Cancelling WarParty");
			aiPlanDestroy(partyPlan);
			partyPlan = -1;
		}
	}
}

//==============================================================================
/* useWarPartiesLakota
	Get the maximum amount of soldiers which is after 30 minutes.
	I'm going to assume we reach the second age after a maximum of 5 minutes
	and only then does this minInterval counter start.
*/
//==============================================================================
rule useWarPartiesLakota
inactive
minInterval 1500
{
	xsSetRuleMinIntervalSelf(60); // Keep this rule up to date more frequently now.
	if (xsGetTime() < 30 * 60 * 1000) // We haven't passed 30 minutes in game yet.
	{
		return;
	}
	
	bool canDisableSelf = researchSimpleTech(cTechBigSiouxDogSoldiers, -1, 
		getUnit(cUnitTypeAgeUpBuilding, cMyID, cUnitStateAlive), 50);
		
	if (canDisableSelf == true)
	{
		xsDisableSelf();
	}
}

//==============================================================================
// useAsianLevy
// TODO this can't handle multiple Town Centers yet.
//==============================================================================
rule useAsianLevy
inactive
minInterval 10
{
	static int levyPlan = -1;
	vector mainBaseVec = cInvalidVector;

	mainBaseVec = kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID));

	int towncenterID = getUnitByLocation(cUnitTypeAgeUpBuilding, cMyID, cUnitStateAlive, mainBaseVec, 40.0);

	int levy1 = cTechypAssemble;
	int levy2 = cTechypMuster;
	if ((cMyCiv == cCivIndians) || (cMyCiv == cCivSPCIndians))
	{
		levy1 = cTechypAssembleIndians;
		levy2 = cTechypMusterIndians;
	}

	if ((towncenterID < 0) || ((kbBuildingTechGetStatus(levy1, towncenterID) != cTechStatusObtainable) &&
		(kbBuildingTechGetStatus(levy2, towncenterID) != cTechStatusObtainable)))
	{
		if (levyPlan >= 0)
		{
			debugMilitary("Destroying levy plan");
			aiPlanDestroy(levyPlan);
			levyPlan = -1;
		}
		return;
	}

	int enemyCount = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia,
		cUnitStateAlive, mainBaseVec, 40.0);
	int enemyCavalryCount = getUnitCountByLocation(cUnitTypeAbstractCavalry, cPlayerRelationEnemyNotGaia,
		cUnitStateAlive, mainBaseVec, 40.0) +
		getUnitCountByLocation(cUnitTypeAbstractCoyoteMan, cPlayerRelationEnemyNotGaia, cUnitStateAlive, mainBaseVec, 40.0);
	int allyCount = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationAlly, cUnitStateAlive, mainBaseVec, 40.0);

	if (levyPlan < 0)
	{ // Create a new plan.
		if (enemyCount >= (allyCount + 5))
		{ // We're behind by 5 or more.
			if (kbBuildingTechGetStatus(levy1, towncenterID) == cTechStatusObtainable && (enemyCavalryCount * 2 >= enemyCount))
			{
				levyPlan = createSimpleResearchPlanSpecificBuilding(levy1, towncenterID, cMilitaryEscrowID, 99); // Extreme priority
			}
			else if (kbBuildingTechGetStatus(levy2, towncenterID) == cTechStatusObtainable)
			{
				levyPlan = createSimpleResearchPlanSpecificBuilding(levy2, towncenterID, cMilitaryEscrowID, 99); // Extreme priority
			}
			if (levyPlan >= 0)
			{
				debugMilitary("Starting a levy plan, there are " + enemyCount + " enemy units in my base against " + allyCount + " friendlies");
				aiPlanSetDesiredResourcePriority(levyPlan, 85);
			}
		}
	}
	else // Plan exists, make sure it's still needed.
	{
		if ((enemyCount > (allyCount + 2)) && (aiPlanGetState(levyPlan) >= 0))
		{ // Do nothing
			debugMilitary("Still waiting for levy.");
		}
		else
		{
			debugMilitary("Destroying levy plan.");
			aiPlanDestroy(levyPlan);
			levyPlan = -1;
		}
	}
}

//==============================================================================
// consulateLevy
// We assume our Consulate is in our main base and we can only defend that base with this logic.
//==============================================================================
rule consulateLevy
inactive
minInterval 10
{
	// Disable this rule whenever we've used the Levy or we've changed relations.
	int techStatus = kbTechGetStatus(cTechypConsulateOttomansSettlerCombat);
	if ((techStatus == cTechStatusActive) ||
		(techStatus != cTechStatusObtainable))
	{
		xsDisableSelf();
		return;
	}
	
	int consulateID = getUnit(cUnitTypeypConsulate, cMyID, cUnitStateAlive);
	if (consulateID < 0)
	{
		return;
	}
	vector mainBaseVec = kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID));

	int enemyCount = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, 
		cPlayerRelationEnemyNotGaia, cUnitStateAlive, mainBaseVec, 40.0);
	int allyCount = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, 
		cPlayerRelationAlly, cUnitStateAlive, mainBaseVec, 40.0);
	
	int levyPlan = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechypConsulateOttomansSettlerCombat);
	if (levyPlan < 0) // No plan, see if we need one.
	{
		if (enemyCount >= allyCount + 5)
		{ // We're behind by 5 or more.
			debugMilitary("Starting Consulate levy plan, there are " + enemyCount + 
				" enemy units in my base against " + allyCount + " allies");
			createSimpleResearchPlanSpecificBuilding(cTechypConsulateOttomansSettlerCombat,
				consulateID, cMilitaryEscrowID, 99, 99);
		}
	}
	else // Plan exists, make sure it's still needed.
	{
		if ((enemyCount > allyCount + 2) && (aiPlanGetState(levyPlan) >= 0))
		{ // Do nothing
			debugMilitary("Still waiting for Consulate levy");
		}
		else
		{
			debugMilitary("Destroying Consulate levy plan");
			aiPlanDestroy(levyPlan);
		}
	}
}


//==============================================================================
// useAfricanLevy
// We can only defend our main base with this logic.
//==============================================================================
rule useAfricanLevy
inactive
minInterval 10
{
	static int levyMaintainPlan = -1;
	static float spearmanCost = -1.0;
	static float bowmanCost = -1.0;
	static float gunnerCost = -1.0;
	if (spearmanCost == -1.0) // First run.
	{
		spearmanCost = kbUnitCostPerResource(cUnitTypedeSpearmanLevy, cResourceInfluence);
		bowmanCost = kbUnitCostPerResource(cUnitTypedeBowmanLevy, cResourceInfluence);
		gunnerCost = kbUnitCostPerResource(cUnitTypedeGunnerLevy, cResourceInfluence);
	}
	vector mainBaseVec = kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID));
	int palaceID = getUnitByLocation(cUnitTypedePalace, cMyID, cUnitStateAlive, mainBaseVec, 40.0);
	int houseID = getUnitByLocation(gHouseUnit, cMyID, cUnitStateAlive, mainBaseVec, 40.0);
	float currentInfluenceAmount = kbResourceGet(cResourceInfluence);

	if (mainBaseVec == cInvalidVector || (houseID < 0 && palaceID < 0) ||
		currentInfluenceAmount < spearmanCost)
	{
		if (levyMaintainPlan >= 0)
		{
			aiPlanDestroy(levyMaintainPlan);
			levyMaintainPlan = -1;
		}
		return;
	}

	int enemyCount = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, cUnitStateAlive, mainBaseVec, 40.0);
	int enemyCavalryCount = getUnitCountByLocation(cUnitTypeAbstractCavalry, cPlayerRelationEnemyNotGaia, cUnitStateAlive, mainBaseVec, 40.0) +
		getUnitCountByLocation(cUnitTypeAbstractCoyoteMan, cPlayerRelationEnemyNotGaia, cUnitStateAlive, mainBaseVec, 40.0);
	int allyCount = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationAlly, cUnitStateAlive, mainBaseVec, 40.0);

	if (enemyCount > allyCount + 5)
	{	// We're behind by 5 or more thus we need to get some levies.

		int levyPUID = -1;
		int numberToMaintain = 0;
		if (enemyCavalryCount * 2 >= enemyCount)
		{ // Counter a force consisting of mainly Cavalry with Spearman.
			levyPUID = cUnitTypedeSpearmanLevy;
			numberToMaintain = currentInfluenceAmount / spearmanCost;
		}
		else if (palaceID >= 0)
		{
			levyPUID = cUnitTypedeGunnerLevy;
			numberToMaintain = currentInfluenceAmount / gunnerCost;
		}
		else
		{
			levyPUID = cUnitTypedeBowmanLevy;
			numberToMaintain = currentInfluenceAmount / bowmanCost;
		}

		// Don't overtrain when we have a lot of Influence.
		if (numberToMaintain > 6)
		{
			numberToMaintain = 6;
		}

		debugMilitary("We have to use levies and decided we should make " + numberToMaintain + " " + kbGetProtoUnitName(levyPUID));
		// If we don't have a plan make one otherwise adjust how many to maintain for the existing plan.
		if (levyMaintainPlan < 0)
		{
			levyMaintainPlan = createSimpleMaintainPlan(levyPUID, numberToMaintain, false, kbBaseGetMainID(cMyID), 1);
			aiPlanSetDesiredResourcePriority(levyMaintainPlan, 99);
		}
		else
		{
			aiPlanSetVariableInt(levyMaintainPlan, cTrainPlanUnitType, 0, levyPUID);
			aiPlanSetVariableInt(levyMaintainPlan, cTrainPlanNumberToMaintain, 0, numberToMaintain);
		}
	}
	else if (levyMaintainPlan >= 0)
	{
		aiPlanDestroy(levyMaintainPlan);
		levyMaintainPlan = -1;
	}
}

//==============================================================================
// Explorer Rescue and Ransom
//==============================================================================
rule rescueExplorer
inactive
minInterval 120
{
	static int rescuePlan = -1;

	// Destroy old rescue plan (if any).
	if (rescuePlan >= 0)
	{
		aiPlanDestroy(rescuePlan);
		rescuePlan = -1;
		debugMilitary("Killing old rescue plan");
	}
	
	// Let the ransom rule take care of this if we have enough coin.
	if (kbResourceGet(cResourceGold) >= 1300)
	{
		debugMilitary("Ransom explorer instead of attempting to rescue");
		return;
	}

	int fallenExplorerID = aiGetFallenExplorerID();
	// We need a fallen Explorer for all of this to make sense right.
	if (fallenExplorerID < 0)
	{
		return;
	}
	
	// Only try to rescue an Explorer that can actually be revived.
	if (kbUnitGetHealth(fallenExplorerID) < 0.3)
	{
		debugMilitary("Explorer too weak to be rescued");
		return;
	}

	// Decide on which unit type to use for rescue attempt.
	int scoutType = findBestScoutType();
	
	// Get position of fallen explorer and send scout unit there.
	vector fallenExplorerLocation = kbUnitGetPosition(fallenExplorerID);
	rescuePlan = aiPlanCreate("Rescue Explorer", cPlanExplore);
	if (rescuePlan >= 0)
	{
		aiPlanAddUnitType(rescuePlan, scoutType, 1, 1, 1);
		aiPlanAddWaypoint(rescuePlan, fallenExplorerLocation);
		aiPlanSetVariableBool(rescuePlan, cExplorePlanDoLoops, 0, false);
		aiPlanSetVariableBool(rescuePlan, cExplorePlanAvoidingAttackedAreas, 0, false);
		aiPlanSetVariableInt(rescuePlan, cExplorePlanNumberOfLoops, 0, -1);
		aiPlanSetRequiresAllNeedUnits(rescuePlan, true);
		aiPlanSetDesiredPriority(rescuePlan, 42);
		aiPlanSetActive(rescuePlan);
		debugMilitary("Trying to rescue explorer");
	}
}


rule ransomExplorer
inactive
minInterval 120
{
	int fallenExplorerID = aiGetFallenExplorerID();
	// Use only when we have enough coin in the bank.
	if ((fallenExplorerID < 0) || (kbResourceGet(cResourceGold) < 1300))
	{
		return;
	}

	if (aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanProtoUnitCommandID, cProtoUnitCommandRansomExplorer) >= 0)
	{
		return;
	}

	int tcID = getUnit(cUnitTypeTownCenter, cMyID, cUnitStateAlive);

	if (tcID < 0)
	{
		return;
	}

	aiRansomExplorer(fallenExplorerID, cMilitaryEscrowID, getUnit(cUnitTypeTownCenter, cMyID, cUnitStateAlive));
	debugMilitary("Creating ransom explorer plan");
}

//==============================================================================
// Monopoly Functions
//==============================================================================
rule monopolyManager
minInterval 21
inactive
{
	if (aiTreatyActive() == true)
	{
		debugMilitary("Monopoly unavailable because treaty is active still");
		return;
	}
	
	if (kbUnitCount(cMyID, cUnitTypeTradingPost, cUnitStateAlive) < 1)
	{
		return;
	}
	
	// Check if we have enough Trading Posts to activate the Monopoly.
	if (aiReadyForTradeMonopoly() == true)
	{
		debugMilitary("We have enough Trading Posts to start a monopoly");
		if (kbResourceGet(cResourceGold) >= kbTechCostPerResource(cTechTradeMonopoly, cResourceGold) &&
			kbResourceGet(cResourceFood) >= kbTechCostPerResource(cTechTradeMonopoly, cResourceFood) &&
			kbResourceGet(cResourceWood) >= kbTechCostPerResource(cTechTradeMonopoly, cResourceWood))
		{
			debugMilitary("We have enough resources to activate the monopoly, so attempt it");
			if (aiDoTradeMonopoly() == true)
			{
				debugMilitary("We've started a trade monopoly");
			}
			else
			{
				debugMilitary("We've tried to start a monopoly but it somehow failed");
			}
		}
		else
		{
			debugMilitary("But we don't have the resources to activate it");
		}
	}
}

void KOTHVictoryStartHandler(int teamID = -1)
{
	// Sanity check, idk if needed at all.
	if (teamID < 0)
	{
		return;
	}
	debugMilitary("King of the Hill timer started by team: " + teamID);

	gIsKOTHRunning = true;
	gKOTHTeam = teamID;
}

void KOTHVictoryEndHandler(int teamID = -1)
{
	gIsKOTHRunning = false;
	gKOTHTeam = -1;
	debugMilitary("Team: " + teamID + " have not completed the King of the Hill timer");
}

rule summerPalaceTacticMonitor
inactive
mininterval 1
{
	// Check for the Summer Palace, if we don't find one we've lost it and we can disable this Rule.
	int summerPalaceID = getUnit(gSummerPalacePUID);
	if (summerPalaceID < 0)
	{
		xsDisableSelf();
		return;
	}

	for (i = 0; < 3)
	{
		int armyPUID = kbUnitPickGetResult(gLandUnitPicker, i);
		switch (armyPUID)
		{
			case cUnitTypeypTerritorialArmy:
			{
				aiUnitSetTactic(summerPalaceID, cTacticTerritorialArmy);
				xsSetRuleMinIntervalSelf(196);
				return;
			}
			case cUnitTypeypForbiddenArmy:
			{
				aiUnitSetTactic(summerPalaceID, cTacticForbiddenArmy);
				xsSetRuleMinIntervalSelf(295);
				return;
			}
			case cUnitTypeypImperialArmy:
			{
				aiUnitSetTactic(summerPalaceID, cTacticImperialArmy);
				xsSetRuleMinIntervalSelf(256);
				return;
			}
			case cUnitTypeypOldHanArmy:
			{
				aiUnitSetTactic(summerPalaceID, cTacticOldHanArmy);
				xsSetRuleMinIntervalSelf(154);
				return;
			}
			case cUnitTypeypStandardArmy:
			{
				aiUnitSetTactic(summerPalaceID, cTacticStandardArmy);
				xsSetRuleMinIntervalSelf(152);
				return;
			}
			case cUnitTypeypMingArmy:
			{
				aiUnitSetTactic(summerPalaceID, cTacticMingArmy); 
				xsSetRuleMinIntervalSelf(159);
				return;
			}
		}
	}

	// We didn't find any suitable armies in our unit picker, default to Standard Army.
	aiUnitSetTactic(summerPalaceID, cTacticStandardArmy);
	xsSetRuleMinIntervalSelf(152);
}

rule mansabdarMonitor
inactive
minInterval 30
{
	if ( (kbUnitCount(cMyID, cUnitTypeypWICharminarGate2, cUnitStateAlive) < 0) &&
		(kbUnitCount(cMyID, cUnitTypeypWICharminarGate3, cUnitStateAlive) < 0) &&
		(kbUnitCount(cMyID, cUnitTypeypWICharminarGate4, cUnitStateAlive) < 0) &&
		(kbUnitCount(cMyID, cUnitTypeypWICharminarGate5, cUnitStateAlive) < 0) )
	{
		return;
	}

	static int mansabdarRajputPlan = -1;
	static int mansabdarSepoyPlan = -1;
	static int mansabdarGurkhaPlan = -1;
	static int mansabdarSowarPlan = -1;
	static int mansabdarZamburakPlan = -1;
	static int mansabdarFlailElephantPlan = -1;
	static int mansabdarMahoutPlan = -1;
	static int mansabdarHowdahPlan = -1;
	static int mansabdarSiegeElephantPlan = -1;

	int numRajputs = -1;
	int numSepoys = -1;
	int numGurkhas = -1;
	int numSowars = -1;
	int numZamburaks = -1;
	int numFlailElephants = -1;
	int numMahouts = -1;
	int numHowdahs = -1;
	int numSiegeElephants = -1;

	// Check number of rajputs, maintain mansabdar rajput as long as there are at least 10
	numRajputs = kbUnitCount(cMyID, cUnitTypeypRajput, cUnitStateAlive);
	if (numRajputs >= 10)
	{
		// Create/update maintain plan
		if (mansabdarRajputPlan < 0)
		{
			mansabdarRajputPlan = createSimpleMaintainPlan(cUnitTypeypRajputMansabdar, 1, false, kbBaseGetMainID(cMyID), 1);
		}
		else
		{
			aiPlanSetVariableInt(mansabdarRajputPlan , cTrainPlanNumberToMaintain, 0, 1);
		}
	}
	else
	{
		// Update maintain plan, provided it exists
		if (mansabdarRajputPlan >= 0)
		{
			aiPlanSetVariableInt(mansabdarRajputPlan , cTrainPlanNumberToMaintain, 0, 0);
		}
	}
	// Check number of sepoys, maintain mansabdar sepoy as long as there are at least 10
	numSepoys = kbUnitCount(cMyID, cUnitTypeypSepoy, cUnitStateAlive);
	if (numSepoys >= 10)
	{
		// Create/update maintain plan
		if (mansabdarSepoyPlan < 0)
		{
			mansabdarSepoyPlan = createSimpleMaintainPlan(cUnitTypeypSepoyMansabdar, 1, false, kbBaseGetMainID(cMyID), 1);
		}
		else
		{
			aiPlanSetVariableInt(mansabdarSepoyPlan , cTrainPlanNumberToMaintain, 0, 1);
		}
	}
	else
	{
		// Update maintain plan, provided it exists
		if (mansabdarSepoyPlan >= 0)
		{
			aiPlanSetVariableInt(mansabdarSepoyPlan , cTrainPlanNumberToMaintain, 0, 0);
		}
	}
	// Check number of gurkhas, maintain mansabdar gurkha as long as there are at least 10
	numGurkhas = kbUnitCount(cMyID, cUnitTypeypNatMercGurkha, cUnitStateAlive);
	if (numGurkhas >= 10)
	{
		// Create/update maintain plan
		if (mansabdarGurkhaPlan < 0)
		{
			mansabdarGurkhaPlan = createSimpleMaintainPlan(cUnitTypeypNatMercGurkhaJemadar, 1, false, kbBaseGetMainID(cMyID), 1);
		}
		else
		{
			aiPlanSetVariableInt(mansabdarGurkhaPlan , cTrainPlanNumberToMaintain, 0, 1);
		}
	}
	else
	{
		// Update maintain plan, provided it exists
		if (mansabdarGurkhaPlan >= 0)
		{
			aiPlanSetVariableInt(mansabdarGurkhaPlan , cTrainPlanNumberToMaintain, 0, 0);
		}
	}
	// Check number of sowars, maintain mansabdar sowar as long as there are at least 7
	numSowars = kbUnitCount(cMyID, cUnitTypeypSowar, cUnitStateAlive);
	if (numSowars >= 7)
	{
		// Create/update maintain plan
		if (mansabdarSowarPlan < 0)
		{
			mansabdarSowarPlan = createSimpleMaintainPlan(cUnitTypeypSowarMansabdar, 1, false, kbBaseGetMainID(cMyID), 1);
		}
		else
		{
			aiPlanSetVariableInt(mansabdarSowarPlan , cTrainPlanNumberToMaintain, 0, 1);
		}
	}
	else
	{
		// Update maintain plan, provided it exists
		if (mansabdarSowarPlan >= 0)
		{
			aiPlanSetVariableInt(mansabdarSowarPlan , cTrainPlanNumberToMaintain, 0, 0);
		}
	}
	// Check number of zamburaks, maintain mansabdar zamburak as long as there are at least 10
	numZamburaks = kbUnitCount(cMyID, cUnitTypeypZamburak, cUnitStateAlive);
	if (numZamburaks >= 10)
	{
		// Create/update maintain plan
		if (mansabdarZamburakPlan < 0)
		{
			mansabdarZamburakPlan = createSimpleMaintainPlan(cUnitTypeypZamburakMansabdar, 1, false, kbBaseGetMainID(cMyID), 1);
		}
		else
		{
			aiPlanSetVariableInt(mansabdarZamburakPlan , cTrainPlanNumberToMaintain, 0, 1);
		}
	}
	else
	{
		// Update maintain plan, provided it exists
		if (mansabdarZamburakPlan >= 0)
		{
			aiPlanSetVariableInt(mansabdarZamburakPlan , cTrainPlanNumberToMaintain, 0, 0);
		}
	}
	// Check number of flail elephants, maintain mansabdar flail elephant as long as there are at least 6
	numFlailElephants = kbUnitCount(cMyID, cUnitTypeypMercFlailiphant, cUnitStateAlive);
	if (numFlailElephants >= 6)
	{
		// Create/update maintain plan
		if (mansabdarFlailElephantPlan < 0)
		{
			mansabdarFlailElephantPlan = createSimpleMaintainPlan(cUnitTypeypMercFlailiphantMansabdar, 1, false, kbBaseGetMainID(cMyID), 1);
		}
		else
		{
			aiPlanSetVariableInt(mansabdarFlailElephantPlan , cTrainPlanNumberToMaintain, 0, 1);
		}
	}
	else
	{
		// Update maintain plan, provided it exists
		if (mansabdarFlailElephantPlan >= 0)
		{
			aiPlanSetVariableInt(mansabdarFlailElephantPlan , cTrainPlanNumberToMaintain, 0, 0);
		}
	}
	// Check number of mahouts, maintain mansabdar mahout as long as there are at least 3
	numMahouts = kbUnitCount(cMyID, cUnitTypeypMahout, cUnitStateAlive);
	if (numMahouts >= 3)
	{
		// Create/update maintain plan
		if (mansabdarMahoutPlan < 0)
		{
			mansabdarMahoutPlan = createSimpleMaintainPlan(cUnitTypeypMahoutMansabdar, 1, false, kbBaseGetMainID(cMyID), 1);
		}
		else
		{
			aiPlanSetVariableInt(mansabdarMahoutPlan , cTrainPlanNumberToMaintain, 0, 1);
		}
	}
	else
	{
		// Update maintain plan, provided it exists
		if (mansabdarMahoutPlan >= 0)
		{
			aiPlanSetVariableInt(mansabdarMahoutPlan , cTrainPlanNumberToMaintain, 0, 0);
		}
	}
	// Check number of howdahs, maintain mansabdar howdah as long as there are at least 3
	numHowdahs = kbUnitCount(cMyID, cUnitTypeypHowdah, cUnitStateAlive);
	if (numHowdahs >= 3)
	{
		// Create/update maintain plan
		if (mansabdarHowdahPlan < 0)
		{
			mansabdarHowdahPlan = createSimpleMaintainPlan(cUnitTypeypHowdahMansabdar, 1, false, kbBaseGetMainID(cMyID), 1);
		}
		else
		{
			aiPlanSetVariableInt(mansabdarHowdahPlan , cTrainPlanNumberToMaintain, 0, 1);
		}
	}
	else
	{
		// Update maintain plan, provided it exists
		if (mansabdarHowdahPlan >= 0)
		{
			aiPlanSetVariableInt(mansabdarHowdahPlan , cTrainPlanNumberToMaintain, 0, 0);
		}
	}
	// Check number of siege elephants, maintain mansabdar siege elephant as long as there are at least 3
	numSiegeElephants = kbUnitCount(cMyID, cUnitTypeypSiegeElephant, cUnitStateAlive);
	if (numSiegeElephants >= 3)
	{
		// Create/update maintain plan
		if (mansabdarSiegeElephantPlan < 0)
		{
			mansabdarSiegeElephantPlan = createSimpleMaintainPlan(cUnitTypeypSiegeElephantMansabdar, 1, false, kbBaseGetMainID(cMyID), 1);
		}
		else
		{
			aiPlanSetVariableInt(mansabdarSiegeElephantPlan , cTrainPlanNumberToMaintain, 0, 1);
		}
	}
	else
	{
		// Update maintain plan, provided it exists
		if (mansabdarSiegeElephantPlan >= 0)
		{
			aiPlanSetVariableInt(mansabdarSiegeElephantPlan , cTrainPlanNumberToMaintain, 0, 0);
		}
	}
}


rule daimyoMonitor
inactive
minInterval 30
{
	static int daimyo1Plan = -1;
	static int daimyo2Plan = -1;
	static int daimyo3Plan = -1;
	static int shogunPlan = -1;

	int theShogunateID = getUnit(gTheShogunatePUID);
	// Check for The Shogunate, if we don't find one we've lost it and we can disable this Rule.
	if (theShogunateID < 0)
	{
		aiPlanDestroy(daimyo1Plan);
		aiPlanDestroy(daimyo2Plan);
		aiPlanDestroy(daimyo3Plan);
		aiPlanDestroy(shogunPlan);
		xsDisableSelf();
		return;
	}
	
	int mainBaseID = kbBaseGetMainID(cMyID);
	int numberToMaintain = 0;

	if ((daimyo1Plan < 0) && (kbTechGetStatus(cTechYPHCShipDaimyoAizu) == cTechStatusActive))
	{
		daimyo1Plan = createSimpleMaintainPlan(cUnitTypeypDaimyoKiyomasa, 1, false, mainBaseID, 1);
	}
	if (daimyo2Plan < 0)
	{
		daimyo2Plan = createSimpleMaintainPlan(cUnitTypeypDaimyoMasamune, 1, false, mainBaseID, 1);
	}
	if ((daimyo3Plan < 0) && (kbTechGetStatus(cTechYPHCShipDaimyoSatsuma) == cTechStatusActive))
	{
		daimyo3Plan = createSimpleMaintainPlan(cUnitTypeypDaimyoMototada, 1, false, mainBaseID, 1);
	}
	if ((shogunPlan < 0) && (kbTechGetStatus(cTechYPHCShipShogunate) == cTechStatusActive))
	{
		shogunPlan = createSimpleMaintainPlan(cUnitTypeypShogunTokugawa, 1, false, mainBaseID, 1);
	}

	if (aiGetMilitaryPop() >= 15)
	{
		numberToMaintain = 1;
	}

	// 1 Daimyo and 1 Shogun.
	if (daimyo1Plan >= 0)
	{
		aiPlanSetVariableInt(daimyo1Plan, cTrainPlanNumberToMaintain, 0, numberToMaintain);
	}
	if (daimyo2Plan >= 0)
	{
		if (daimyo1Plan < 0)
		{
			aiPlanSetVariableInt(daimyo2Plan, cTrainPlanNumberToMaintain, 0, numberToMaintain);
		}
		else
		{
			aiPlanSetVariableInt(daimyo2Plan, cTrainPlanNumberToMaintain, 0, 0);
		}
	}
	if (daimyo3Plan >= 0)
	{
		if ((daimyo1Plan < 0) && (daimyo2Plan < 0))
		{
			aiPlanSetVariableInt(daimyo3Plan, cTrainPlanNumberToMaintain, 0, numberToMaintain);
		}
		else
		{
			aiPlanSetVariableInt(daimyo3Plan, cTrainPlanNumberToMaintain, 0, 0);
		}
	}

	if (shogunPlan >= 0)
	{
		aiPlanSetVariableInt(shogunPlan, cTrainPlanNumberToMaintain, 0, numberToMaintain);
	}
}
