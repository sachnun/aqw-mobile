package ext {
    import flash.external.ExtensionContext;

    public class ForegroundService {
        private static const EXT_ID:String = "com.aqw.foreground";
        private var ctx:ExtensionContext;

        public function ForegroundService() {
            ctx = ExtensionContext.createExtensionContext(EXT_ID, null);
        }

        public function start():Boolean {
            if (ctx == null) {
                return false;
            }
            return Boolean(ctx.call("startService"));
        }

        public function stop():Boolean {
            if (ctx == null) {
                return false;
            }
            return Boolean(ctx.call("stopService"));
        }

        public function dispose():void {
            if (ctx != null) {
                ctx.dispose();
                ctx = null;
            }
        }
    }
}
