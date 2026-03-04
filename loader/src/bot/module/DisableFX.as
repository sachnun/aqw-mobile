package bot.module {

	/**
	 * Disable FX module - disables visual effects on all avatars.
	 * Disables visual effects (spell effects, etc.) on all avatars.
	 * Stores original FX references and restores them when disabled.
	 */
	public class DisableFX extends Module {

		private var _fxStore:Object = {};
		private var _wasEnabled:Boolean = false;

		public function DisableFX() {
			super("DisableFX");
		}

		override public function onToggle(game:*):void {
			if (game == null || game.world == null) return;

			if (!_wasEnabled && enabled) {
				_fxStore = {};
			}
			_wasEnabled = enabled;

			for each (var avatar:* in game.world.avatars) {
				if (enabled) {
					if (avatar.pMC != null && avatar.pMC.spFX != null) {
						_fxStore[avatar.uid] = avatar.rootClass.spFX;
					}
					avatar.rootClass.spFX = null;
				} else {
					if (_fxStore[avatar.uid] !== undefined) {
						avatar.rootClass.spFX = _fxStore[avatar.uid];
					}
				}
			}
		}

		override public function onFrame(game:*):void {
			onToggle(game);
		}
	}
}
