package core {

	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;

	public class World {

		private static const TICK_MAX:int = 30;
		private static const TICK_DEPTH_SORT:int = 2;
		private static const TICK_SPECIAL_DEPTH:int = 6;
		private static const TICK_COMBAT_QUEUE:int = 2;
		private static const TICK_BOOST:int = 150;

		private static const arrQuality:Array = ["LOW", "MEDIUM", "HIGH"];

		public function World(main:Main) {
			this.main = main;
		}

		private var main:Main;

		private var _tickDepthSort:int = 0;
		private var _tickSpecialDepth:int = 0;
		private var _tickCombatQueue:int = 0;
		private var _tickBoost:int = 0;

		private var fpsTS:Number = 0;
		private var fpsQualityCounter:int = 0;
		private var fpsArrayQuality:Array = [];

		private var tickSum:Number = 0;
		private var tickList:Array = [];

		private var combatDisplayTime:uint;

		public function onZManagerEnterFrame(event:Event):void {
			calculateFPS();

			if (++_tickDepthSort >= TICK_DEPTH_SORT) {
				_tickDepthSort = 0;
				sortCharactersByDepth();
			}

			if (++_tickSpecialDepth >= TICK_SPECIAL_DEPTH) {
				_tickSpecialDepth = 0;
				enforceSpecialMapDepth();
			}

			if (++_tickBoost >= TICK_BOOST) {
				_tickBoost = 0;
				checkAndRenewBoosts();
			}

			if (++_tickCombatQueue >= TICK_COMBAT_QUEUE) {
				_tickCombatQueue = 0;
				processCombatDisplayQueue();
			}
		}

		private function calculateFPS():void {
			if (main.game == null || main.game.ui == null || main.game.ui.mcFPS == null || !main.game.ui.mcFPS.visible) {
				return;
			}

			if (fpsTS != 0) {
				var fpsTime:int = new Date().getTime() - fpsTS;

				var x:Number = 0;

				if (tickList.length == TICK_MAX) {
					x = tickList.shift();
				}

				tickList.push(fpsTime);
				tickSum = (tickSum + fpsTime) - x;

				var tickFinal:Number = 1000 / (tickSum / tickList.length);

				if (main.game.ui.mcFPS.visible) {
					main.game.ui.mcFPS.txtFPS.text = tickFinal.toPrecision(3);
				}

				if (++fpsQualityCounter % TICK_MAX == 0 && tickList.length == TICK_MAX && main.game.userPreference.data.quality == "AUTO") {
					fpsArrayQuality.push(tickFinal);

					if (fpsArrayQuality.length == 5) {
						var quality:Number = 0;

						for (var i:int = 0; i < fpsArrayQuality.length; i++) {
							quality += fpsArrayQuality[i];
						}

						const qualityFinal:Number = quality / fpsArrayQuality.length;
						const qualityIndex:int = arrQuality.indexOf(main.game.stage.quality);

						if (qualityFinal < 12 && qualityIndex > 0) {
							main.game.stage.quality = arrQuality[(qualityIndex - 1)];
						}

						if (qualityFinal >= 12 && qualityIndex < 2) {
							main.game.stage.quality = arrQuality[(qualityIndex + 1)];
						}

						fpsArrayQuality = [];
					}
				}
			}

			fpsTS = new Date().getTime();
		}

		private function sortCharactersByDepth():void {
			if (main.game == null || main.game.world == null || main.game.world.CHARS == null) {
				return;
			}

			var entries:Array = [];
			var displayObject:DisplayObject;

			for (var i:int = 0; i < main.game.world.CHARS.numChildren; i++) {
				displayObject = main.game.world.CHARS.getChildAt(i);

				entries.push({
					dio: displayObject,
					oy: displayObject.y
				});

				displayObject = null;
			}

			entries.sortOn("oy", Array.NUMERIC);

			var child:MovieClip;
			var currentIndex:int;

			for (var j:int = 0; j < entries.length; j++) {
				child = entries[j].dio;
				currentIndex = main.game.world.CHARS.getChildIndex(child);

				if (currentIndex != j) {
					main.game.world.CHARS.swapChildrenAt(currentIndex, j);
				}

				child = null;
			}

			entries = null;
		}

		private function enforceSpecialMapDepth():void {
			if (main.game == null || main.game.world == null || main.game.world.strFrame != "Enter") {
				return;
			}

			switch (main.game.world.strMapName) {
				case "trickortreat":
					bringToFront("mcPlayerNPCTrickOrTreat");
					break;
				case "caroling":
					bringToFront("mcPlayerNPCCaroling");
					break;
			}
		}

		private function bringToFront(npcName:String):void {
			if (main.game == null || main.game.world == null || main.game.world.CHARS == null) {
				return;
			}

			const target:DisplayObject = main.game.world.CHARS.getChildByName(npcName);

			if (target) {
				main.game.world.CHARS.setChildIndex(target, main.game.world.CHARS.numChildren - 1);
				return;
			}

			try {
				const firstMonster:Array = main.game.world.getMonsters(1);
				if (firstMonster != null && firstMonster.length > 0 && firstMonster[0] != null && firstMonster[0].pMC != null) {
					main.game.world.CHARS.setChildIndex(firstMonster[0].pMC, main.game.world.CHARS.numChildren - 1);
				}
			} catch (e:Error) {
			}
		}

		private function checkAndRenewBoosts():void {
			if (main.game == null) {
				return;
			}

			if (main.game.stage == null) {
				if (main.game.world == null) {
					return;
				}
				main.game.world.killTimers();
				main.game.world.killListeners();
				return;
			}

			if (main.game.ui == null || main.game.ui.mcPortrait == null || main.game.world == null) {
				return;
			}

			if (main.game.world == null || main.game.world.myAvatar == null || main.game.world.myAvatar.objData == null) {
				return;
			}

			const now:Number = new Date().getTime();
			const portrait:MovieClip = main.game.ui.mcPortrait;

			checkBoost(now, portrait.hasOwnProperty("iconBoostXP") ? portrait.iconBoostXP : null, "iBoostXP", "xpboost");
			checkBoost(now, portrait.hasOwnProperty("iconBoostG") ? portrait.iconBoostG : null, "iBoostG", "gboost");
			checkBoost(now, portrait.hasOwnProperty("iconBoostRep") ? portrait.iconBoostRep : null, "iBoostRep", "repboost");
			checkBoost(now, portrait.hasOwnProperty("iconBoostCP") ? portrait.iconBoostCP : null, "iBoostCP", "cpboost");
		}

		private function checkBoost(now:Number, icon:*, boostKey:String, boostType:String):void {
			if (icon == null || main.game == null || main.game.world == null || main.game.world.myAvatar == null || main.game.world.myAvatar.objData[boostKey] == null) {
				return;
			}

			if (!icon.hasOwnProperty("boostTS") || !icon.hasOwnProperty(boostKey)) {
				return;
			}

			const expiresAt:Number = icon.boostTS + icon[boostKey] * 1000;

			if (expiresAt < now + 1000) {
				main.game.sfc.sendXtMessage("zm", "serverUseItem", ["-", boostType], "str", -1);
			}
		}

		private function processCombatDisplayQueue():void {
			if (main.game == null || main.game.world == null) {
				return;
			}

			if (!combatDisplayTime) {
				combatDisplayTime = new Date().time;
			}

			const now:uint = new Date().time;

			if (now - combatDisplayTime < 250) {
				return;
			}

			var didDisplay:Boolean = false;

			if (main.game.world.hasOwnProperty("ActionResults") && main.game.world.ActionResults.length > 0) {
				main.game.world.showActionImpact(main.game.world.ActionResults.shift());
				didDisplay = true;
			}

			if (main.game.world.hasOwnProperty("ActionResultsAura") && main.game.world.ActionResultsAura.length > 0 && main.game.world.hasOwnProperty("showAuraImpact")) {
				main.game.world.showAuraImpact(main.game.world.ActionResultsAura.shift());
				didDisplay = true;
			}

			if (main.game.world.hasOwnProperty("ActionResultsMon") && main.game.world.ActionResultsMon.length > 0) {
				main.game.world.showActionImpact(main.game.world.ActionResultsMon.shift());
				didDisplay = true;
			}

			if (didDisplay) {
				combatDisplayTime = new Date().time;
			}
		}

	}

}
