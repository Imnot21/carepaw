"""Mark paper edits: wrong text red + strikethrough, new text green.

Usage: python redline.py <unpacked dir>
"""
import html
import random
import re
import sys

D = sys.argv[1]
PATH = f'{D}/word/document.xml'
xml = open(PATH, encoding='utf8').read()

RED, GREEN = 'FF0000', '00B050'
ORDER = ['rStyle', 'rFonts', 'b', 'bCs', 'i', 'iCs', 'caps', 'smallCaps',
         'strike', 'dstrike', 'outline', 'shadow', 'emboss', 'imprint',
         'noProof', 'snapToGrid', 'vanish', 'webHidden', 'color', 'spacing',
         'w', 'kern', 'position', 'sz', 'szCs', 'highlight', 'u', 'effect',
         'bdr', 'shd', 'fitText', 'vertAlign', 'rtl', 'cs', 'em', 'lang',
         'eastAsianLayout', 'specVanish', 'oMath']


def style(rpr, color, strike):
    inner = rpr[len('<w:rPr>'):-len('</w:rPr>')] if rpr else ''
    kids = re.findall(r'<w:(\w+)\b[^>]*?/>|<w:(\w+)\b[^>]*>.*?</w:\2>', inner, flags=re.S)
    parts = [m.group(0) for m in re.finditer(r'<w:(\w+)\b[^>]*?/>|<w:(\w+)\b[^>]*>.*?</w:\2>', inner, flags=re.S)]
    keep = []
    for el in parts:
        name = re.match(r'<w:(\w+)', el).group(1)
        if name in ('strike', 'dstrike', 'color'):
            continue
        keep.append((name, el))
    keep.append(('color', f'<w:color w:val="{color}"/>'))
    if strike:
        keep.append(('strike', '<w:strike/>'))
    keep.sort(key=lambda kv: ORDER.index(kv[0]) if kv[0] in ORDER else 99)
    return '<w:rPr>' + ''.join(el for _, el in keep) + '</w:rPr>'


def t(text):
    esc = html.escape(text, quote=False)
    return f'<w:t xml:space="preserve">{esc}</w:t>'


def segments(p):
    """Split paragraph into (kind, data) items: ('other', xml) or
    ('run', rpr, [('text', str) | ('raw', xml)])."""
    out = []
    pos = 0
    for m in re.finditer(r'<w:r(?: [^>]*)?>(.*?)</w:r>', p, flags=re.S):
        out.append(('other', p[pos:m.start()]))
        body = m.group(1)
        rm = re.match(r'<w:rPr>.*?</w:rPr>', body, flags=re.S)
        rpr = rm.group(0) if rm else ''
        inner = body[len(rpr):]
        kids = []
        q = 0
        for tm in re.finditer(r'<w:t(?: [^>]*)?>([^<]*)</w:t>|<w:t/>', inner):
            if tm.start() > q:
                kids.append(('raw', inner[q:tm.start()]))
            kids.append(('text', html.unescape(tm.group(1) or '')))
            q = tm.end()
        if q < len(inner):
            kids.append(('raw', inner[q:]))
        out.append(('run', rpr, kids))
        pos = m.end()
    out.append(('other', p[pos:]))
    return out


def ptext(p):
    return ''.join(k[1] for s in segments(p) if s[0] == 'run' for k in s[2] if k[0] == 'text')


def apply(p, edits):
    """edits: list of (start, end, new). start..end is struck red; new
    (may be '') is inserted green right after it."""
    segs = segments(p)
    edits = sorted(edits)
    out = []
    off = 0
    for s in segs:
        if s[0] == 'other':
            out.append(s[1])
            continue
        _, rpr, kids = s
        for kind, data in kids:
            if kind == 'raw':
                out.append(f'<w:r>{rpr}{data}</w:r>')
                continue
            # cut this text at every edit boundary inside it
            a, b = off, off + len(data)
            cuts = {a, b}
            for st, en, _ in edits:
                for c in (st, en):
                    if a < c < b:
                        cuts.add(c)
            cuts = sorted(cuts)
            for x, y in zip(cuts, cuts[1:]):
                piece = data[x - a:y - a]
                struck = any(st <= x and y <= en for st, en, _ in edits)
                r = style(rpr, RED, True) if struck else rpr
                out.append(f'<w:r>{r}{t(piece)}</w:r>')
                for st, en, new in edits:
                    if en == y and new and (st < en or st == y):
                        out.append(f'<w:r>{style(rpr, GREEN, False)}{t(new)}</w:r>')
            if a == b:
                for st, en, new in edits:
                    if st == en == a and new:
                        out.append(f'<w:r>{style(rpr, GREEN, False)}{t(new)}</w:r>')
            off = b
    return ''.join(out)


def find(text, old, after=None):
    base = text.index(after) + len(after) if after else 0
    i = text.index(old, base)
    return i


used_ids = set(re.findall(r'w14:paraId="([0-9A-F]+)"', xml))


def new_id():
    while True:
        v = f'{random.randint(0x10000000, 0x7FFFFFFF):08X}'
        if v not in used_ids:
            used_ids.add(v)
            return v


def new_para(template, text):
    ppr = re.search(r'<w:pPr>.*?</w:pPr>', template, flags=re.S)
    ppr = ppr.group(0) if ppr else ''
    ppr = re.sub(r'<w:pageBreakBefore/>', '', ppr)
    first = re.search(r'<w:r(?: [^>]*)?>(<w:rPr>.*?</w:rPr>)?', template, flags=re.S)
    rpr = first.group(1) or '' if first else ''
    rpr = re.sub(r'<w:highlight [^>]*/>', '', rpr)
    runs = []
    for i, part in enumerate(text.split('\t')):
        tab = '<w:tab/>' if i else ''
        runs.append(f'<w:r>{style(rpr, GREEN, False)}{tab}{t(part) if part else ""}</w:r>')
    return f'<w:p w14:paraId="{new_id()}" w14:textId="77777777">{ppr}{"".join(runs)}</w:p>'


head, rest = xml.split('<w:body>', 1)
spans = [m.span() for m in re.finditer(r'<w:p[ >].*?</w:p>', rest, flags=re.S)]
P = [rest[a:b] for a, b in spans]
orig = list(P)
after = {}  # index -> list of new paragraph xml appended after it
log = []


def rep(i, old, new, ctx=None, expect=None):
    text = ptext(P[i])
    if expect:
        assert expect in text, (i, expect, text[:120])
    s = find(text, old, ctx)
    P[i] = apply(P[i], [(s, s + len(old), new)])
    log.append(f'P{i}: "{old}" -> "{new}"')


def ins(i, anchor, new):
    """Insert green `new` right after `anchor`."""
    text = ptext(P[i])
    s = text.index(anchor) + len(anchor)
    P[i] = apply(P[i], [(s, s, new)])
    log.append(f'P{i}: + "{new}"')


def strike_all(i, expect):
    text = ptext(P[i])
    assert expect in text, (i, expect, text)
    lead = len(text) - len(text.lstrip())
    end = len(text.rstrip())
    P[i] = apply(P[i], [(lead, end, '')])
    log.append(f'P{i}: struck "{text.strip()[:60]}"')


def add_after(i, template_i, lines):
    after.setdefault(i, []).extend(new_para(orig[template_i], l) for l in lines)
    log.append(f'after P{i}: + {len(lines)} paragraph(s)')


# ---------------- Section 3: paper layout ----------------
# 14. Table of Contents, Chapter 3
rep(61, 'TECHNICAL BACKGROUND', 'PROJECT ANALYSIS AND DESIGN', expect='CHAPTER 3')
for i, e in [(62, 'Research Approach'), (63, 'Methodology'),
             (64, 'Planning Phase'), (65, 'Requirement Elicitation Phase')]:
    strike_all(i, e)
add_after(65, 63, ['System Requirements', 'Use Case Diagram'])
add_after(66, 66, ['Entity-Relationship Diagram', 'System Architecture Diagram'])

# 13. List of Tables
for i, e in [(80, 'Project Scope Table'), (81, 'Data Gathering Tools Table'),
             (82, 'Functional and Non-Functional Requirements Table')]:
    strike_all(i, e)
tables = ['Gap Analysis of CAREPAW', 'System Requirements', 'Functional Requirements',
          'Non-Functional Requirements'] + [
    f'Data Dictionary \u2013 {n}' for n in
    ['users', 'pets', 'appointments', 'queueEntries', 'medicalRecords', 'inventoryItems',
     'inventoryBatches', 'inventoryTransactions', 'scanRecords', 'notifications',
     'notificationPreferences', 'auditLogs']]
add_after(82, 80, [f'{n}\t{name}' for n, name in enumerate(tables, 1)])

# 12 + 13. List of Figures
for i, e in [(86, 'Agile System Development Life Cycle'), (87, 'Gantt'),
             (88, 'Use Case Diagram'), (89, 'Context Diagram'),
             (90, 'Level 1 Data Flow Diagram'), (91, 'User Interface Mockups')]:
    strike_all(i, e)
figures = ['Organizational Structure of DocMyk\u2019s PILA VET HUB',
           'Existing Workflow of DocMyk\u2019s PILA VET HUB',
           'Conceptual Framework of CarePaw', 'Waterfall Model of CarePaw',
           'Waterfall Model', 'Use Case Diagram of CarePaw',
           'Entity-Relationship Diagram of CarePaw', 'System Architecture Diagram of CarePaw']
add_after(91, 86, [f'{n}\t{name}' for n, name in enumerate(figures, 1)])

# Figure numbers on the Chapter 3 captions (needed by the List of Figures)
assert ptext(P[430]).strip() == 'Figure'
ins(430, 'Figure', ' 6 Use Case Diagram of CarePaw')
assert ptext(P[436]).strip() == 'Figure'
ins(436, 'Figure ', '7 Entity-Relationship Diagram of CarePaw')
add_after(479, 436, ['Figure 8 System Architecture Diagram of CarePaw'])

# 15. Data dictionary table numbers and the leftover note
dd = [(438, 'users'), (440, 'pets'), (444, 'appointments'), (447, 'queueEntries'),
      (451, 'medicalRecords'), (455, 'inventoryItems'), (459, 'inventoryBatches'),
      (462, 'inventoryTransactions'), (465, 'scanRecords'), (469, 'notifications'),
      (472, 'notificationPreferences'), (475, 'auditLogs')]
for n, (i, name) in enumerate(dd):
    old = f'3.{9 + n}'
    rep(i, old, str(5 + n), expect=f'Table {old}. Data Dictionary')
    assert name in ptext(P[i]), (i, name)
rep(438, ' (Mali table number hanggang baba)', '')

# 16. Missing "Mobile-Based" in the title
ins(320, 'The proposed CarePaw: A ', 'Mobile-Based ')

# ---------------- Section 2: system alignment ----------------
# 3. Pet details the app saves
rep(101, 'age, gender', 'birth date, sex', expect="animal's name, age, gender, breed")
# 1. No Firebase Cloud Messaging in the app
rep(229, ', and Firebase Cloud Messaging for notifications',
    ', and Firebase AI Logic for connecting to the Gemini AI model. '
    'Notifications are shown through the device\u2019s built-in notification feature')
# 2. The clinic can book for a pet its owner registered
rep(230, ' or book appointments on their behalf', '')
ins(230, 'are not transferred into the system.',
    ' The clinic owner/admin may book an appointment only for a pet that its owner has already registered.')
# 4. Definition of Terms: Firebase
rep(250, 'notification', 'AI reading', expect='database, user login, and notification services')
# 5. Related Technologies list + short paragraphs
ins(320, 'Firebase Authentication, ', 'Firebase AI Logic, Firebase App Check, Flutter Local Notifications, ')
assert ptext(P[333]).startswith('Firebase Authentication is')
add_after(333, 333, [
    'Firebase App Check is a Firebase service that helps confirm that requests to the '
    'backend come from the genuine application. In CarePaw, it will check that database '
    'and AI requests come from the official CarePaw app, which helps block requests from '
    'modified or unknown clients.'])
assert ptext(P[335]).startswith('SharedPreferences is')
add_after(335, 333, [
    'Flutter Local Notifications is a Flutter package that displays notifications through '
    'the device\u2019s own notification system. In CarePaw, it will show appointment and queue '
    'alerts on the user\u2019s phone, and tapping an alert will open the related screen.'])
assert ptext(P[339]).startswith('The Google Gemini API')
add_after(339, 333, [
    'Firebase AI Logic is a Firebase service that allows a mobile application to use '
    'Google\u2019s Gemini AI models through its Firebase project. In CarePaw, it will send '
    'captured medicine images to the Google Gemini API and return the extracted details, '
    'so no Gemini API key is stored in the application.'])
# 6. What Cloud Functions does
rep(329, 'validating protected requests and communicating securely with the Google Gemini API for medicine scanning',
    'permanently deleting a user account, which the mobile application cannot do by itself')
# 8. Fields the AI reads
rep(338, 'medicine names, dosage, quantity, batch numbers, and expiration dates',
    'medicine names and strength, quantity, unit, lot or batch numbers, expiration dates, and supplier names')
rep(340, 'medicine name, dosage, quantity, batch number, and expiration date',
    'medicine name and strength, quantity, unit, lot or batch number, expiration date, and supplier')
# 7. Gemini goes through Firebase AI Logic
rep(342, 'Firebase Cloud Functions', 'Firebase AI Logic')
rep(342, 'validate AI responses', 'check that each AI response follows a fixed set of fields')
# 11. No inventory warnings
rep(470, ', queue updates, and inventory warnings', ' and queue updates')

# ---------------- write ----------------
out = []
pos = 0
for i, (a, b) in enumerate(spans):
    out.append(rest[pos:a])
    out.append(P[i])
    out.extend(after.get(i, []))
    pos = b
out.append(rest[pos:])
open(PATH, 'w', encoding='utf8').write(head + '<w:body>' + ''.join(out))
print('\n'.join(log))
print(len(log), 'edits')
