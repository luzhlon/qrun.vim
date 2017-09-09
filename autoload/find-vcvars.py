"""
File: find-vcvars.py
Author: luzhlon
Github: https://github.com/luzhlon
Description: A script to help the vim find the vcvarsall.bat
"""

import winreg as wr
import platform, os

vs_vers = {
    '15.0' : 'VS150COMNTOOLS',
    '14.0' : 'VS140COMNTOOLS',
    '12.0' : 'VS120COMNTOOLS',
    '11.0' : 'VS110COMNTOOLS',
    '10.0' : 'VS100COMNTOOLS',
    '9.0'  : 'VS90COMNTOOLS',
    '8.0'  : 'VS80COMNTOOLS',
    '7.1'  : 'VS71COMNTOOLS',
    '7.0'  : 'VS70COMNTOOLS',
    '6.0'  : 'VS60COMNTOOLS',
    '5.0'  : 'VS50COMNTOOLS',
    '4.2'  : 'VS42COMNTOOLS'}

def QuerySoftware(key, val = ''):
    """
    Query the registry under HKEY_LOCAL_MACHINE\SOFTWARE[\Wow6432Node]
    """

    key = ('SOFTWARE\\Wow6432Node\\' \
            if platform.architecture()[0] == '64bit' \
            else 'SOFTWARE\\')  + key
    try:
        k = wr.OpenKeyEx(wr.HKEY_LOCAL_MACHINE, key, access=wr.KEY_QUERY_VALUE)
        return wr.QueryValueEx(k, val)[0] if val else wr.QueryValue(k, val)
    except Exception:
        return ''
    finally:
        wr.CloseKey(k)

def FindVcvarsall(ver):
    """
    Find the vcvarsall.bat by visual studio's version
    """
    global vs_vers

    for path in [vspath + subpath \
                 for vspath in [os.environ.get(vs_vers.get(ver), ''), \
                                QuerySoftware('Microsoft\VisualStudio\SxS\VS7', ver)]
                 for subpath in ['\\VC\\vcvarsall.bat', '\\VC\\Auxiliary\\Build\\vcvarsall.bat']]:
        if os.path.exists(path):
            return path
    return ''

vers = list(vs_vers.keys())
# sort the versions from large to small
vers.sort(key = lambda x: float(x), reverse = True)
_ = ''
for ver in vers:
    path = FindVcvarsall(ver)
    if path:
        _ = path; break
