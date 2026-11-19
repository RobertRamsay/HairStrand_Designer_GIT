"""Proves that an edit changed COMMENTS ONLY.

Run from the project root:
    python tools/check_comments_only.py                 # every changed .gml / .fsh / .vsh
    python tools/check_comments_only.py path1 path2     # just these files

For each file it takes the last committed version (git HEAD) and the version on
disk, strips every comment from both, and compares what is left line by line
(ignoring indentation and blank lines). If anything other than a comment
differs, it prints the first few differing lines and exits with an error.

Strings are respected, so "//" inside a string is not treated as a comment.
"""
import subprocess, sys


def strip_comments(src):
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        nxt = src[i + 1] if i + 1 < n else ''
        if c == '/' and nxt == '/':                       # line comment
            while i < n and src[i] != '\n':
                i += 1
        elif c == '/' and nxt == '*':                     # block comment
            j = src.find('*/', i + 2)
            block = src[i:(j + 2 if j >= 0 else n)]
            out.append('\n' * block.count('\n'))          # keep the line structure
            i = j + 2 if j >= 0 else n
        elif c == '@' and nxt in '"\'':                   # verbatim string @"..." / @'...'
            q = nxt
            j = src.find(q, i + 2)
            j = n - 1 if j < 0 else j
            out.append(src[i:j + 1])
            i = j + 1
        elif c == '"':                                    # normal string with \ escapes
            j = i + 1
            while j < n and src[j] != '"' and src[j] != '\n':
                j += 2 if src[j] == '\\' else 1
            out.append(src[i:j + 1])
            i = j + 1
        else:
            out.append(c)
            i += 1
    lines = [' '.join(ln.split()) for ln in ''.join(out).split('\n')]
    return [ln for ln in lines if ln]


def head_version(path):
    r = subprocess.run(['git', 'show', 'HEAD:' + path], capture_output=True)
    return None if r.returncode != 0 else r.stdout.decode('utf-8', 'replace')


def main():
    files = sys.argv[1:]
    if not files:
        r = subprocess.run(['git', 'diff', '--name-only', 'HEAD'], capture_output=True, text=True)
        files = [f for f in r.stdout.split('\n') if f.endswith(('.gml', '.fsh', '.vsh'))]
    bad = 0
    for f in files:
        f = f.replace('\\', '/')
        old = head_version(f)
        if old is None:
            print('NEW FILE (nothing to compare):', f)
            continue
        new = open(f, encoding='utf-8', errors='replace').read()
        a, b = strip_comments(old.replace('\r\n', '\n')), strip_comments(new.replace('\r\n', '\n'))
        if a == b:
            print('ok   ', f)
            continue
        bad += 1
        print('CODE CHANGED:', f, '(%d code lines before, %d after)' % (len(a), len(b)))
        shown = 0
        for k in range(max(len(a), len(b))):
            x = a[k] if k < len(a) else '<end>'
            y = b[k] if k < len(b) else '<end>'
            if x != y:
                print('   was:', x[:150])
                print('   now:', y[:150])
                shown += 1
                if shown >= 3:
                    break
    print('%d file(s) checked, %d with code changes' % (len(files), bad))
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
