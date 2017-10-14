"""The main script loader. Provides cached script lookup.


"""

from .MathematicaScript import MathematicaScript

mathematica_script_cache = {
    # The cached loaded scripts
    };

def mathematica_script(script):
    if script in mathematica_script_cache:
        m_script = mathematica_script_cache[script]
    else:
        try:
            m_script = MathematicaScript(script)
            mathematica_script_cache[script] = m_script
        except MathematicaScriptException:
            m_script = None
    return m_script
