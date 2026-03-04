package bot.module {

	/**
	 * Disable Collisions module - removes wall collision arrays.
	 * Removes wall collision arrays, allowing the player to walk through walls.
	 */
	public class DisableCollisions extends Module {

		private var _old:*;
		private var _oldR:*;

		public function DisableCollisions() {
			super("DisableCollisions");
		}

		override public function onToggle(game:*):void {
			if (game == null || game.world == null) return;

			var world:* = game.world;
			if (enabled) {
				_old = world.arrSolid;
				_oldR = world.arrSolidR;
				world.arrSolid = [];
				world.arrSolidR = [];
			} else {
				if (_old != null) world.arrSolid = _old;
				if (_oldR != null) world.arrSolidR = _oldR;
			}
		}

		override public function onFrame(game:*):void {
			onToggle(game);
		}
	}
}
