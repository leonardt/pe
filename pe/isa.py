from .config import config
from .pe import PE, CONST
import ast
import inspect
import textwrap
import astor
from collections import namedtuple

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

regb = namedtuple("regb", ["mode", "value"])

# FIXME: signed should probably be True or False not 1 or 0?
def op(opcode, b=None, signed=0):
    def wrapper(fn):
        # FIXME: Should we have this extra layer of calling?
        def wrapped():
            _pe = PE(opcode, fn, signed=signed)
            if b is not None:
                if not isinstance(b, reg):
                    raise ValueError("Expected tuple for the form (CONST, 1)")
                _pe.regb(*b)
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
        keywords = []
        for arg, val in zip(statement.args.args, statement.args.defaults):
            keywords.append(ast.keyword(arg.arg, val))
        statement.decorator_list.append(
            ast.Call(func=ast.Name(id='op', ctx=ast.Load()),
                 args=[],
                 keywords=keywords))
        statement.args = args
        exec(astor.to_source(statement), globals())

@functional_unit
def _PE(a, b, c, d):
    def or_(opcode=0x12):
        return a | b

    def and_(opcode=0x13):
        return a & b

    def xor(opcode=0x14):
        return a ^ b

    # TODO: Why are there two ops at 0x15?
    def inv(opcode=0x15):
        return ~a


    # TODO: Nice syntax: def neg(opcode=0x15, b=reg(CONST, 1)):
    def neg(opcode=0x15, b=(CONST, 1)):
        return ~a + b

    def lshr(opcode=0xf):
        return a >> b

    def ashr(opcode=0x10, signed=1):
        return a >> b

    def lshl(opcode=0x11):
        return a << b

    def add(opcode=0x0):
        # res_p = cout
        return a + b + d

    def sub(opcode=0x1):
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

