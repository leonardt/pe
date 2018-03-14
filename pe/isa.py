from .config import config
from .pe import PE, CONST
import ast
import inspect
import textwrap
import astor

def get_ast(obj):
    indented_program_txt = inspect.getsource(obj)
    program_txt = textwrap.dedent(indented_program_txt)
    return ast.parse(program_txt)

__all__  = ['or_', 'and_', 'xor', 'inv']
__all__ += ['lshr', 'lshl', 'ashr']
__all__ += ['add', 'sub']
__all__ += ['min', 'max', 'abs']
__all__ += ['eq', 'ge', 'le']
__all__ += ['sel']
__all__ += ['const']


# FIXME: signed should probably be True or False not 1 or 0?
def op(opcode, regb=None, signed=0):
    def wrapper(fn):
        # FIXME: Should we have this extra layer of calling?
        def wrapped():
            _pe = PE(opcode, fn, signed=signed)
            if regb is not None:
                if not isinstance(regb, tuple):
                    raise ValueError("Expected tuple for the form (CONST, 1)")
                _pe.regb(*regb)
            return _pe
        return wrapped
    return wrapper

def functional_unit(fn):
    module = get_ast(fn)
    function_def = module.body[0]
    args = function_def.args
    ops = []
    for statement in function_def.body:
        if not isinstance(statement, ast.FunctionDef):
            raise SyntaxError("Can only define functions in the body of the @functional_unit")
        statement.args = args
        string = astor.to_source(ast.Module([statement]))
        exec(astor.to_source(statement), globals())

@functional_unit
def _PE(a, b, c, d):
    @op(0x12)
    def or_():
        return a | b

    @op(0x13)
    def and_():
        return a & b

    @op(0x14)
    def xor():
        return a ^ b

    # TODO: Why are there two ops at 0x15?
    @op(0x15)
    def inv():
        return ~a

    @op(0x15, regb=(CONST, 1))
    def neg():
        return ~a + b

    @op(0xf)
    def lshr():
        return a >> b

    @op(0x10, signed=1)
    def ashr():
        return a >> b

    @op(0x11)
    def lshl():
        return a << b


    @op(0x0)
    def add():
        # res_p = cout
        return a + b + d

    @op(0x1)
    def sub():
        # res = (a - b) + c
        return (a - b) + d


def eq():
    # res?
    return PE( 0x6, lambda a, b, c, d: a+b ).cond( lambda ge, eq, le: eq )

def ge(signed):
    # res = a >= b ? a : b (comparison should be signed/unsigned)
    return PE( 0x4, lambda a, b, c, d: a if a >= b else b, signed=signed ).cond( lambda ge, eq, le: ge ) 

max = ge

def le(signed):
    # res = a <= b ? a : b 
    return PE( 0x5, lambda a, b, c, d: a if a <= b else b, signed=signed ).cond( lambda ge, eq, le: le )

min = le

@op(0x3)
def abs(a, b, c, d):
    return a if a >= 0 else ~a+1


def sel():
    return PE( 0x8, lambda a, b, c, d: b if d else a )

def const(value):
    return PE( 0x0, lambda a, b, c, d: a ).rega( CONST, value )

