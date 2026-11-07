"""Pure contract tests: no QML, compositor, audio, Docker or network execution."""
import ast
import contextlib
import hashlib
import importlib.util
import io
import json
import signal
import struct
import subprocess
import sys
import tempfile
import unittest
from collections import Counter
from pathlib import Path
from unittest.mock import patch

HERE = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(HERE))
SPEC = importlib.util.spec_from_file_location('runtime', HERE / 'qml-runtime-fixture.py')
RUNTIME = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RUNTIME)
from qml_runtime import contracts, headless, pipewire


class Contracts(unittest.TestCase):
    def test_default_inert(self):
        with patch.object(sys, 'argv', ['qml-runtime-fixture.py']), patch.object(RUNTIME, 'execute') as execute, contextlib.redirect_stdout(io.StringIO()):
            RUNTIME.main()
        execute.assert_not_called()

    def test_explicit_execution_requires_all_inputs(self):
        with patch.object(sys, 'argv', ['qml-runtime-fixture.py', '--execute']), contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit): RUNTIME.main()

    def test_marker_lifecycle_failure_closed(self):
        self.assertTrue(RUNTIME.harness_verdict(0, False, None, 1))
        for args in [(1, False, None, 1), (0, True, None, 1), (0, False, 'failure', 1), (0, False, None, 0), (0, False, None, 2)]:
            self.assertFalse(RUNTIME.harness_verdict(*args))

    def synthetic_harness(self, lines, wait_for_bootstrap=False, response="started\n", required=False):
        real_popen = subprocess.Popen
        owned = []
        calls = []
        script = "import os,signal,sys; "
        if wait_for_bootstrap:
            script += "signal.signal(signal.SIGUSR1,lambda *_:(print('FIXTURE_OK',flush=True),sys.exit(0))); "
        script += "os.write(1," + repr(lines.encode()) + "); "
        script += "signal.pause()" if wait_for_bootstrap else "sys.exit(0)"
        def spawn(_command, **kwargs):
            child = real_popen([sys.executable, "-c", script], **kwargs)
            owned.append(child)
            return child
        def bootstrap(command, **_kwargs):
            calls.append(command)
            owned[0].send_signal(signal.SIGUSR1)
            return subprocess.CompletedProcess(command, 0, stdout=response, stderr="")
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "RuntimeOwnedTest.qml"
            with patch.object(RUNTIME.subprocess, "Popen", side_effect=spawn), patch.object(RUNTIME.subprocess, "run", side_effect=bootstrap):
                result = RUNTIME.run_harness(path, "FIXTURE_OK", Path(directory), None, deadline=2, quickshell="/owned/quickshell", bootstrap_required=required)
            for call in calls:
                self.assertEqual(call, ["/owned/quickshell", "ipc", "--path", str(path), "call", "qml-ci-bootstrap", "start"])
        return result, calls

    def test_bootstrap_requires_both_events_and_fixed_owned_command(self):
        for lines in (" DEBUG qml: QML_CI_BOOTSTRAP_READY\n INFO: Configuration Loaded\n",
                      " INFO: Configuration Loaded\n DEBUG qml: QML_CI_BOOTSTRAP_READY\n"):
            with self.subTest(order=lines):
                result, calls = self.synthetic_harness(lines, True)
                self.assertTrue(result["accepted"])
                self.assertEqual(len(calls), 1)
                self.assertEqual(result["bootstrap_ready_count"], 1)
                self.assertTrue(result["ipc_bootstrap"]["after_configuration_loaded"])

    def test_bootstrap_missing_loaded_rejects_even_with_marker(self):
        result, calls = self.synthetic_harness(" DEBUG qml: QML_CI_BOOTSTRAP_READY\nFIXTURE_OK\n")
        self.assertFalse(result["accepted"])
        self.assertEqual(calls, [])

    def test_duplicate_bootstrap_readiness_rejects(self):
        result, calls = self.synthetic_harness(" INFO: Configuration Loaded\n DEBUG qml: QML_CI_BOOTSTRAP_READY\n DEBUG qml: QML_CI_BOOTSTRAP_READY\nFIXTURE_OK\n")
        self.assertFalse(result["accepted"])
        self.assertLessEqual(len(calls), 1)

    def test_bootstrap_error_response_retained_and_rejected(self):
        result, calls = self.synthetic_harness(" INFO: Configuration Loaded\n DEBUG qml: QML_CI_BOOTSTRAP_READY\n", True, "unexpected\n")
        self.assertFalse(result["accepted"])
        self.assertEqual(len(calls), 1)
        self.assertEqual(result["ipc_bootstrap"]["stdout"], "unexpected\n")
        for value in ({"exit": 255, "stdout": "started", "stderr": ""},
                      {"exit": 0, "stdout": "started\nextra", "stderr": ""},
                      {"exit": 0, "stdout": "started", "stderr": "warning"}):
            self.assertFalse(RUNTIME.bootstrap_verdict(value))

    def test_ordinary_harness_unchanged_and_no_output_derived_arguments(self):
        result, calls = self.synthetic_harness("FIXTURE_OK\n")
        self.assertTrue(result["accepted"])
        self.assertEqual(calls, [])
        for line in (b" DEBUG qml: QML_CI_BOOTSTRAP_READY", b" DEBUG qml: QML_CI_BOOTSTRAP_READY arbitrary\n",
                     b"QML_CI_BOOTSTRAP_READY\n", b" WARN qml: QML_CI_BOOTSTRAP_READY\n"):
            self.assertEqual(RUNTIME.bootstrap_ready_count(line), 0)

    def test_new_transport_cannot_omit_bootstrap_and_print_only_success(self):
        self.assertEqual(RUNTIME.BOOTSTRAP_CASES, {('p2p','RuntimeIpcTransportTest.qml'), ('mmw','RuntimeIpcTransportTest.qml')})
        result, calls = self.synthetic_harness(" INFO: Configuration Loaded\nFIXTURE_OK\n", required=True)
        self.assertFalse(result['accepted'])
        self.assertTrue(result['bootstrap_required'])
        self.assertEqual(calls, [])

    def test_bootstrap_session_probe_never_signals_another_group(self):
        with patch.object(RUNTIME.os, 'killpg', side_effect=ProcessLookupError) as probe:
            self.assertTrue(RUNTIME.owned_session_empty(12345))
            probe.assert_called_once_with(12345, 0)
        for effect in (None, PermissionError):
            with patch.object(RUNTIME.os, 'killpg', side_effect=effect):
                self.assertFalse(RUNTIME.owned_session_empty(12345))
        with self.assertRaises(AssertionError):RUNTIME.owned_session_empty(0)

    def test_owned_helper_audit_both_operations_and_failure_controls(self):
        import os
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); path = root/'audit'
            valid = [{"operation":"settings-reconcile","accepted":True}, {"operation":"events-list","accepted":True}]
            def write(rows):
                path.write_text(''.join(json.dumps(row)+'\n' for row in rows)); path.chmod(0o600)
            write(valid); self.assertEqual(RUNTIME.fixture_helper_audit(path), valid)
            for rows in (valid[:1], [{"operation":"service-start","accepted":True}],
                         [valid[0], {"operation":"events-list","accepted":False}],
                         [valid[0], {"operation":"events-list","accepted":True,"extra":1}]):
                write(rows)
                with self.assertRaises(AssertionError):RUNTIME.fixture_helper_audit(path)
            write(valid); path.chmod(0o644)
            with self.assertRaises(AssertionError):RUNTIME.fixture_helper_audit(path)
            write(valid); link=root/'link'; link.symlink_to(path)
            with self.assertRaises(OSError):RUNTIME.fixture_helper_audit(link)
            hard=root/'hard'; os.link(path, hard)
            with self.assertRaises(AssertionError):RUNTIME.fixture_helper_audit(path)
            hard.unlink(); path.write_text('x'*16385); path.chmod(0o600)
            with self.assertRaises(AssertionError):RUNTIME.fixture_helper_audit(path)
            fifo = root/'fifo'; os.mkfifo(fifo, 0o600)
            with self.assertRaises(AssertionError):RUNTIME.fixture_helper_audit(fifo)

    def test_owned_lifecycle_uses_exit_and_config_bound_absence_not_raced_kill(self):
        path = Path('/owned/RuntimeTest.qml')
        report = {'exit': 0, 'stdout': 'No running instances.\n', 'stderr': '',
                  'checked_config_path': str(path)}
        self.assertTrue(RUNTIME.owned_lifecycle_verdict(0, report, path))
        self.assertFalse(RUNTIME.owned_lifecycle_verdict(-15, report, path))
        self.assertFalse(RUNTIME.owned_lifecycle_verdict(1, report, path))
        self.assertFalse(RUNTIME.owned_lifecycle_verdict(0, report, Path('/foreign/Test.qml')))
        self.assertFalse(RUNTIME.owned_lifecycle_verdict(0, {**report, 'exit': 255}, path))
        for stdout in ('malformed', '[{"config_path":"/owned/RuntimeTest.qml"}]',
                       '[{"wrong_key":"/foreign/Test.qml"}]'):
            self.assertFalse(RUNTIME.owned_lifecycle_verdict(0, {**report, 'stdout': stdout}, path))
        self.assertTrue(RUNTIME.owned_lifecycle_verdict(0, {**report, 'stdout': '[]'}, path))
        self.assertFalse(RUNTIME.owned_lifecycle_verdict(0, {**report, 'stdout': '[]', 'stderr': 'ERROR'}, path))

    def test_raced_connection_refused_kill_retained_after_natural_success(self):
        # Emit marker but keep the original child alive until the kill command
        # selects it; then exit naturally before the simulated socket connect.
        real_popen = subprocess.Popen
        children = []
        def spawn(_command, **kwargs):
            script = "import os,signal,sys; signal.signal(signal.SIGUSR1,lambda *_:sys.exit(0)); os.write(1,b' INFO: Configuration Loaded\\nFIXTURE_OK\\n'); signal.pause()"
            child = real_popen([sys.executable, '-c', script], **kwargs)
            children.append(child)
            return child
        def command(argv, **_kwargs):
            if argv[1] == 'kill':
                children[0].send_signal(signal.SIGUSR1)
                children[0].wait(timeout=1)
                return subprocess.CompletedProcess(argv, 255, stdout='Socket Error QLocalSocket::ConnectionRefusedError\n', stderr='')
            self.assertEqual(argv[1:], ['list', '--all', '--json', '--no-color'])
            return subprocess.CompletedProcess(argv, 0, stdout='No running instances.\n', stderr='')
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'RuntimeOwnedTest.qml'
            with patch.object(RUNTIME.subprocess, 'Popen', side_effect=spawn), patch.object(RUNTIME.subprocess, 'run', side_effect=command):
                result = RUNTIME.run_harness(path, 'FIXTURE_OK', Path(directory), None, deadline=2,
                                             stop_on_marker=True, quickshell='/owned/quickshell')
        self.assertTrue(result['accepted'], result)
        self.assertEqual(result['kill']['exit'], 255)
        self.assertIn('ConnectionRefusedError', result['kill']['stdout'])
        self.assertEqual(result['marker_count'], 1)
        self.assertEqual(result['owned_config_absence']['checked_config_path'], str(path.resolve()))

    def test_dynamic_canonical_inventory_and_palette(self):
        for repo, limit in [('app',8),('p2p',4),('mmw',8),('privacy',12)]:
            with self.subTest(repo=repo), tempfile.TemporaryDirectory() as tmp:
                checkout = Path(tmp); (checkout/'tests').mkdir()
                deadline = 'limit=${3:-${QML_RUNTIME_LIMIT:-4}}' if repo == 'p2p' else 'timeout ' + str(limit) + ' "$quickshell_bin"'
                text = deadline + '\nrun_harness RuntimeExistingTest.qml EXISTING_OK\nrun_harness RuntimePaletteTest.qml PALETTE_OK\n'
                if repo == 'p2p':text += 'run_harness RuntimePluginSmokeTest.qml SMOKE_OK 7\n'
                (checkout/'tests/run_qml_runtime.sh').write_text(text)
                rows = RUNTIME.canonical_contract(checkout, repo)
                self.assertEqual(rows[1]['file'], 'RuntimePaletteTest.qml')
                self.assertEqual(rows[0]['deadline'], limit)
                if repo == 'p2p':self.assertEqual(rows[-1]['deadline'],7)
                (checkout/'tests/run_qml_runtime.sh').write_text(text+'run_harness UNKNOWN UNPARSED\n')
                with self.assertRaises(AssertionError):RUNTIME.canonical_contract(checkout, repo)
                (checkout/'tests/run_qml_runtime.sh').write_text(text+'run_harness RuntimePaletteTest.qml PALETTE_OK\n')
                with self.assertRaises(AssertionError):RUNTIME.canonical_contract(checkout, repo)

    def test_no_unasserted_warning_allowance(self):
        for raw in ['WARN scene: unexpected', 'ERROR qml: broken', 'TypeError: bad', 'deprecated API']:
            self.assertFalse(contracts.warning_assessment(raw, Path('.'), 'privacy', 'RuntimeTest.qml', {'cases':{}}))
        self.assertTrue(contracts.warning_assessment('DEBUG qml: PASS', Path('.'), 'privacy', 'RuntimeTest.qml', {'cases':{}}))

    def test_source_bound_negative_exact_count_and_changed_source(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp); (root/'tests/qml').mkdir(parents=True)
            path=root/'tests/qml/RuntimeTest.qml';path.write_text('negativeCall()')
            entry={'source_files':{'tests/qml/RuntimeTest.qml':hashlib.sha256(path.read_bytes()).hexdigest()},'caller_evidence':['negativeCall()'],'expected_qml_messages':{'expected negative':1}}
            catalog={'cases':{'app/RuntimeTest.qml':entry}}
            assess=lambda raw:contracts.warning_assessment(raw,root,'app','RuntimeTest.qml',catalog)
            self.assertTrue(assess('WARN qml: expected negative'))
            self.assertFalse(assess('WARN qml: expected negative\nWARN qml: expected negative'))
            self.assertFalse(assess('WARN qml: unexpected'))
            self.assertFalse(assess('WARN qml: expected negative\nTypeError: wrong'))
            path.write_text('changed');self.assertFalse(assess('WARN qml: expected negative'))

    def test_exact_scene_negative_rejects_foreign_paths_and_duplicates(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'tests/qml').mkdir(parents=True)
            path = root / 'tests/qml/RuntimeTest.qml'
            path.write_text('negativeCall()')
            line = 'WARN scene: @tests/fixtures/does-not-exist.qml[-1:-1]: File not found'
            catalog = {'cases': {'p2p/RuntimeTest.qml': {'source_files': {'tests/qml/RuntimeTest.qml': hashlib.sha256(path.read_bytes()).hexdigest()}, 'caller_evidence': ['negativeCall()'], 'expected_exact_warning_lines': {line: 1}}}}
            assess = lambda raw: contracts.warning_assessment(raw, root, 'p2p', 'RuntimeTest.qml', catalog)
            self.assertTrue(assess('  ' + line))
            self.assertFalse(assess(line + '\n' + line))
            self.assertFalse(assess(line.replace('@tests/', '@/foreign/tests/')))
            self.assertFalse(assess(line.replace('WARN scene:', 'WARN qml:')))

    def test_catalog_does_not_allow_privacy_spawn_warning(self):
        catalog=json.loads((HERE/'qml-runtime-warnings.json').read_text())
        self.assertFalse(any(key.startswith('privacy/') for key in catalog['cases']))
        self.assertEqual(Counter(key.split('/')[0] for key in catalog['cases']), {'app':4,'mmw':1,'p2p':1})

    def test_real_protocol_registry_requires_sync_and_all_globals(self):
        def string(value):
            data=value.encode()+b'\0';return struct.pack('=I',len(data))+data+b'\0'*((-len(data))%4)
        events=[]
        for n,name in enumerate(sorted(headless.REQUIRED_GLOBALS),1):events.append(headless.header(2,0,struct.pack('=I',n)+string(name)+struct.pack('=I',1)))
        events.append(headless.header(3,0,struct.pack('=I',1)))
        class Socket:
            def __init__(self,data):self.data=data
            def sendall(self,data):pass
            def settimeout(self,value):pass
            def recv(self,count):data,self.data=self.data[:count],self.data[count:];return data
        self.assertEqual(set(headless.inspect_registry(Socket(b''.join(events)))),headless.REQUIRED_GLOBALS)
        with self.assertRaises(RuntimeError):headless.inspect_registry(Socket(b''.join(events[:-1])))
        with self.assertRaises(RuntimeError):headless.inspect_registry(Socket(b''.join(events[1:])))

    def test_pipewire_no_hardware_and_json_stream(self):
        decoder=pipewire.JsonArrays()
        self.assertEqual(decoder.feed(b'[{"id":1,'),[])
        rows=decoder.feed(b'"type":"PipeWire:Interface:Core"}]')[0]
        pipewire.assert_no_hardware(rows)
        for kind in ['PipeWire:Interface:Node','PipeWire:Interface:Device']:
            with self.assertRaises(AssertionError):pipewire.assert_no_hardware([{'id':2,'type':kind}])

    def test_no_sleep_readiness_and_no_private_pins(self):
        for path in [HERE/'qml-runtime-fixture.py',* (HERE/'qml_runtime').glob('*.py')]:
            source=path.read_text();tree=ast.parse(source)
            self.assertNotIn('/home/',source)
            self.assertNotIn('sha256:a814',source)
            self.assertNotIn('original-shell',source)
            self.assertFalse(any(isinstance(node,ast.Call) and isinstance(node.func,ast.Attribute) and node.func.attr=='sleep' for node in ast.walk(tree)))

    def test_owned_cleanup_signals_only_the_created_session(self):
        class Process:
            pid = 2147483000
            def poll(self): return None
            def wait(self, timeout): return 0
        with patch.object(headless.os, 'killpg') as kill:
            headless.stop_owned(Process())
        self.assertTrue(kill.called)
        self.assertTrue(all(call.args[0] == Process.pid for call in kill.call_args_list))
        for path in [HERE/'qml-runtime-fixture.py', HERE/'qml_runtime/pipewire.py']:
            tree = ast.parse(path.read_text())
            for node in ast.walk(tree):
                if isinstance(node,ast.Call) and isinstance(node.func,ast.Attribute) and node.func.attr=='Popen':
                    self.assertTrue(any(arg.arg=='start_new_session' and isinstance(arg.value,ast.Constant) and arg.value.value is True for arg in node.keywords))

    def test_neutral_fixture_uses_empty_configs_not_font_stubs(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);(root/'bin').mkdir();RUNTIME.seed_fixture(root)
            self.assertEqual((root/'home/.config/omarchy/shell.toml').read_text(),'')
            self.assertEqual((root/'home/.local/state/omarchy/current/theme/shell.toml').read_text(),'')
            self.assertFalse((root/'bin/fc-match').exists())


if __name__=='__main__':unittest.main()
