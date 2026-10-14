"""Fresh SnapPy comparison against independently solved Wolfram shapes.
Run prepare, then CompareSnapPy.wl, then report. No SnapPy geometry is sent
into the Wolfram solver; only original dataset records are shared.
"""
import csv, json, sys, platform
from pathlib import Path
from decimal import Decimal, localcontext
import snappy
ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'outputs' / 'snappy-comparison'
NAMES = ['K4a1','K5a1','K6a1','K7a1','K8a1','K9a1','K10a1','K11n1','K12n1','K14n12345']
OUT.mkdir(parents=True, exist_ok=True)

def prepare():
    with (ROOT/'data/knots_and_links_through_14.csv').open() as f:
        records = {r['name']:r for r in csv.DictReader(f) if r['name'] in NAMES}
    selected = [records[n] for n in NAMES]
    (OUT/'samples.json').write_text(json.dumps(selected,indent=2))
    results=[]
    for r in selected:
        result={'name':r['name']}
        try:
            m=snappy.Manifold(r['triangulation'])
            hp=m.high_precision()
            named=snappy.Manifold(r['name']).high_precision()
            result.update(volume=str(hp.volume()), ordinary_volume=str(m.volume()),
                          named_volume=str(named.volume()), solution_type=hp.solution_type(),
                          tetrahedra=hp.num_tetrahedra(), cusps=hp.num_cusps())
        except Exception as e:
            result['error']=repr(e)
        results.append(result)
        print(result,flush=True)
    (OUT/'snappy.json').write_text(json.dumps({'python':sys.version,'executable':sys.executable,
        'snappy':snappy.__version__,'platform':platform.platform(),'results':results},indent=2))

def report():
    fresh=json.loads((OUT/'snappy.json').read_text())
    wolfram=json.loads((OUT/'wolfram.json').read_text())
    assert [s['name'] for s in fresh['results']] == NAMES, 'Missing or reordered SnapPy results'
    assert [w['Name'] for w in wolfram] == NAMES, 'Missing or reordered Wolfram results'
    rows=[]
    with localcontext() as ctx:
        ctx.prec=100
        for s,w in zip(fresh['results'],wolfram):
            assert s['name']==w['Name']
            row={'name':s['name'],'tetrahedra':s.get('tetrahedra'),'snappy_volume':s.get('volume'),
                 'wolfram_volume':w.get('Volume'),'status':'FAIL'}
            if 'volume' in s and w.get('Status')=='Success':
                a=Decimal(s['volume']); b=Decimal(w['Volume'].split('`')[0]); c=Decimal(s['named_volume'])
                diff=abs(a-b); named_diff=abs(a-c)
                row.update(absolute_difference=str(diff),named_difference=str(named_diff),
                           status='PASS' if diff<Decimal('1e-30') and named_diff<Decimal('1e-30')
                           and w['ChecksPassed'] else 'FAIL')
            else:
                row.update(snappy_error=s.get('error'),wolfram_failure=w)
            rows.append(row)
    result={'snappy_version':fresh['snappy'],'tolerance':'1e-30','passed':sum(r['status']=='PASS' for r in rows),
            'total':len(rows),'results':rows,'certified':False}
    (OUT/'comparison.json').write_text(json.dumps(result,indent=2))
    lines=['# Fresh SnapPy / Wolfram volume comparison','',
           f"SnapPy {fresh['snappy']}; Wolfram working precision 120 digits. Absolute tolerance: 1e-30.",
           'Samples selected in advance across 4–14 crossings. No failed samples replaced.',
           'Both engines receive the original triangulation signature. SnapPy is also independently loaded by knot name.',
           'This checks volumes and Wolfram gluing/stationarity diagnostics, not ten Dirichlet domains or rigorous certification.','',
           '| Manifold | Tetrahedra | SnapPy volume (rounded) | Absolute difference | Status |',
           '|---|---:|---:|---:|---|']
    for row in rows:
        v=row.get('snappy_volume')
        shown=format(Decimal(v),'.15f') if v else '—'
        delta=format(Decimal(row['absolute_difference']),'.2E') if 'absolute_difference' in row else '—'
        lines.append(f"| {row['name']} | {row.get('tetrahedra','—')} | {shown} | {delta} | {row['status']} |")
    lines.extend(['',f"Passed: {result['passed']}/{result['total']}. Full decimal strings are retained in comparison.json."])
    (OUT/'comparison.md').write_text('\n'.join(lines)+'\n')
    with (OUT/'comparison.csv').open('w',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=['name','tetrahedra','snappy_volume','wolfram_volume','absolute_difference','named_difference','status'],extrasaction='ignore')
        writer.writeheader();writer.writerows(rows)
    print(json.dumps(result,indent=2))
    return 0 if result['passed']==10 else 1

if __name__=='__main__':
    if len(sys.argv)!=2 or sys.argv[1] not in ('prepare','report'):
        raise SystemExit('Usage: CompareSnapPy.py prepare|report')
    if sys.argv[1]=='prepare':prepare()
    else:raise SystemExit(report())
