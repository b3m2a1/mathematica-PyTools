"""The script loader class

The MathematicaScript class basically loads and 'exec's code in its
class namespace
"""

import os

class MathematicaScriptException(Exception):
    pass

class MathematicaScript(object):
    """ MathematicaScript is the core script loader / runner """
    script_dir = os.path.join(
        os.path.dirname(__file__),
        "scripts"
        )
    def __init__(self, script):
        script_file = script if os.path.exists(script) else os.path.join(self.script_dir, script)
        if os.path.exists(script):
            self._file = script_file
            try:
                f = open(script_file);
                exec(f.read(), self.__dir__)
            finally:
                f.close()
        else:
            raise MathematicaScriptException("couldn't locate script")
