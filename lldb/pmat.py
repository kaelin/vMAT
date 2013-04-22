# See 
# import this into lldb with a command like
# command script import pmat.py
import lldb
import shlex
import optparse

def pmat(debugger, command, result, dict):
  # Use the Shell Lexer to properly parse up command options just like a
  # shell would
  command_args = shlex.split(command)
  parser = create_pmat_options()
  try:
    (options, args) = parser.parse_args(command_args)
  except:
   return

  target = debugger.GetSelectedTarget()
  if target:
    process = target.GetProcess()
    if process:
      frame = process.GetSelectedThread().GetSelectedFrame()
      if frame:
        var = frame.FindVariable(args[0])
        if var:
          array = var.GetChildMemberWithName("matA")
          if array:
            id = array.GetValueAsUnsigned (lldb.LLDB_INVALID_ADDRESS)
            if id != lldb.LLDB_INVALID_ADDRESS:
              debugger.HandleCommand ('po [0x%x dump]' % id)

def create_pmat_options():
  usage = "usage: %prog"
  description='''Print a dump of a vMAT_Array instance.'''
  parser = optparse.OptionParser(description=description, prog='pmat',usage=usage)
  return parser

#
# code that runs when this script is imported into LLDB
#
def __lldb_init_module (debugger, dict):
  # This initializer is being run from LLDB in the embedded command interpreter
  # Make the options so we can generate the help text for the new LLDB
  # command line command prior to registering it with LLDB below

  # add pmat
  parser = create_pmat_options()
  pmat.__doc__ = parser.format_help()
  # Add any commands contained in this module to LLDB
  debugger.HandleCommand('command script add -f %s.pmat pmat' % __name__)
