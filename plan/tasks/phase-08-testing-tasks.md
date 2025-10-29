# Phase 08: Testing Framework Tasks

**Estimated Time**: 20-24 hours
**Dependencies**: Phases 1-7 complete, all components functional

---

## Overview

Implement comprehensive testing framework covering unit tests, integration tests, end-to-end tests, and performance tests. Ensure high code coverage and reliable test automation.

---

### TASK-070: Testing Infrastructure Setup

**Description**: Set up pytest framework with plugins and test directory structure.

**Implementation Steps**:
1. Install pytest, pytest-cov, pytest-asyncio, pytest-mock
2. Create test directory structure:
   ```
   /tests
     /unit
       /scanner
       /dashboard
       /sync
     /integration
     /e2e
     /fixtures
     /conftest.py
   ```
3. Configure pytest.ini with coverage settings
4. Set up test database fixtures

**Acceptance Criteria**:
- [ ] pytest runs successfully with all plugins
- [ ] Test directory structure is complete
- [ ] Coverage reporting configured (target >80%)
- [ ] Test fixtures are reusable

**Time Estimate**: 3-4 hours

---

### TASK-071: Scanner Unit Tests

**Description**: Write unit tests for scanner components (NmapScanner, MarkdownGenerator).

**Test Coverage**:
```python
# tests/unit/scanner/test_nmap_scanner.py
import pytest
from scanner.nmap_scanner import NmapScanner

class TestNmapScanner:
    def test_parse_nmap_output(self):
        scanner = NmapScanner()
        xml_output = """<host><address addr="192.168.1.1"/></host>"""
        result = scanner.parse_nmap_output(xml_output)
        assert result['ip'] == '192.168.1.1'
    
    def test_detect_device_type(self):
        scanner = NmapScanner()
        device_type = scanner.detect_device_type(
            os='Linux', 
            services=['http', 'ssh']
        )
        assert device_type in ['router', 'server', 'switch']
    
    @pytest.mark.asyncio
    async def test_scan_host(self, mock_nmap):
        scanner = NmapScanner()
        result = await scanner.scan_host('192.168.1.1')
        assert result['status'] in ['up', 'down']
```

**Acceptance Criteria**:
- [ ] All scanner functions have unit tests
- [ ] Coverage >90% for scanner module
- [ ] Tests pass in CI/CD pipeline
- [ ] Mock external dependencies (nmap)

**Time Estimate**: 4-5 hours

---

### TASK-072: Dashboard API Unit Tests

**Description**: Write unit tests for Flask API endpoints and business logic.

**Test Coverage**:
```python
# tests/unit/dashboard/test_api.py
import pytest
from dashboard.app import create_app

@pytest.fixture
def client():
    app = create_app(test_config={'TESTING': True})
    with app.test_client() as client:
        yield client

class TestDeviceAPI:
    def test_get_devices(self, client):
        response = client.get('/api/devices')
        assert response.status_code == 200
        assert 'devices' in response.json['data']
    
    def test_get_device_by_ip(self, client, sample_device):
        response = client.get('/api/devices/192.168.1.1')
        assert response.status_code == 200
        assert response.json['data']['device']['device_ip'] == '192.168.1.1'
    
    def test_get_device_not_found(self, client):
        response = client.get('/api/devices/192.168.99.99')
        assert response.status_code == 404
        assert response.json['error']['code'] == 'DEVICE_NOT_FOUND'
    
    def test_trigger_scan(self, client):
        response = client.post('/api/scans/trigger', json={
            'scan_type': 'discovery',
            'subnet': '192.168.1.0/24'
        })
        assert response.status_code == 202
        assert 'scan_id' in response.json['data']
```

**Acceptance Criteria**:
- [ ] All API endpoints have tests
- [ ] Test success and error cases
- [ ] Coverage >85% for API layer
- [ ] Tests are isolated (no database side effects)

**Time Estimate**: 5-6 hours

---

### TASK-073: Database Layer Tests

**Description**: Test database operations, migrations, and queries.

**Test Coverage**:
```python
# tests/unit/dashboard/test_database.py
import pytest
from dashboard.database import DeviceRepository, ServiceRepository

@pytest.fixture
def db_session(tmpdir):
    # Create temporary test database
    db_path = tmpdir.join('test.db')
    # Initialize schema
    # Return session
    yield session

class TestDeviceRepository:
    def test_create_device(self, db_session):
        repo = DeviceRepository(db_session)
        device = repo.create({
            'device_ip': '192.168.1.1',
            'hostname': 'test.local',
            'status': 'up'
        })
        assert device.id is not None
        assert device.device_ip == '192.168.1.1'
    
    def test_update_device(self, db_session, sample_device):
        repo = DeviceRepository(db_session)
        updated = repo.update(sample_device.id, {'hostname': 'new.local'})
        assert updated.hostname == 'new.local'
    
    def test_find_by_ip(self, db_session, sample_device):
        repo = DeviceRepository(db_session)
        found = repo.find_by_ip('192.168.1.1')
        assert found.id == sample_device.id
```

**Acceptance Criteria**:
- [ ] All repository methods tested
- [ ] Test CRUD operations
- [ ] Test complex queries
- [ ] Coverage >90% for database layer

**Time Estimate**: 3-4 hours

---

### TASK-074: Synchronization Tests

**Description**: Test file watching, sync manager, and WebSocket notifications.

**Acceptance Criteria**:
- [ ] Test file watcher detects changes
- [ ] Test sync manager updates database
- [ ] Test WebSocket broadcasts
- [ ] Coverage >80% for sync module

**Time Estimate**: 3-4 hours

---

### TASK-075: Integration Tests

**Description**: Write integration tests for end-to-end workflows.

**Test Scenarios**:
```python
# tests/integration/test_scan_workflow.py
import pytest
from scanner.scanner_daemon import ScannerDaemon
from dashboard.sync import SyncManager

@pytest.mark.integration
class TestScanWorkflow:
    def test_full_scan_to_dashboard(self, scanner, dashboard, sync_manager):
        # Trigger scan
        scan_id = scanner.start_scan('192.168.1.0/24', 'full_scan')
        
        # Wait for scan completion
        scanner.wait_for_completion(scan_id, timeout=300)
        
        # Verify markdown files created
        assert scanner.get_scan_files(scan_id)
        
        # Trigger sync
        sync_manager.sync_now()
        
        # Verify dashboard database updated
        devices = dashboard.get_devices()
        assert len(devices) > 0
        
        # Verify API returns data
        response = dashboard.api_client.get('/api/devices')
        assert response.status_code == 200
```

**Acceptance Criteria**:
- [ ] Full scan-to-dashboard workflow tested
- [ ] API integration tested
- [ ] Sync integration tested
- [ ] Tests run in isolated environment

**Time Estimate**: 4-5 hours

---

### TASK-076: End-to-End Tests

**Description**: Implement E2E tests using Playwright for UI testing.

**Test Coverage**:
```python
# tests/e2e/test_dashboard_ui.py
import pytest
from playwright.sync_api import Page, expect

@pytest.mark.e2e
class TestDashboardUI:
    def test_dashboard_loads(self, page: Page):
        page.goto('http://localhost:5000')
        expect(page.locator('h1')).to_contain_text('nMapping+')
    
    def test_device_list_displays(self, page: Page, sample_devices):
        page.goto('http://localhost:5000')
        # Wait for devices to load
        page.wait_for_selector('.device-card')
        devices = page.locator('.device-card').count()
        assert devices > 0
    
    def test_trigger_scan_ui(self, page: Page):
        page.goto('http://localhost:5000')
        page.click('button[data-testid="trigger-scan"]')
        page.fill('input[name="subnet"]', '192.168.1.0/24')
        page.click('button[type="submit"]')
        expect(page.locator('.notification')).to_contain_text('Scan triggered')
```

**Acceptance Criteria**:
- [ ] UI loads and displays data
- [ ] User interactions work correctly
- [ ] Scan trigger UI functional
- [ ] WebSocket updates visible in UI

**Time Estimate**: 4-5 hours

---

### TASK-077: Performance Tests

**Description**: Implement performance and load tests.

**Test Scenarios**:
```python
# tests/performance/test_api_performance.py
import pytest
import time
from concurrent.futures import ThreadPoolExecutor

@pytest.mark.performance
class TestAPIPerformance:
    def test_get_devices_response_time(self, client):
        start = time.time()
        response = client.get('/api/devices?limit=100')
        duration = time.time() - start
        assert response.status_code == 200
        assert duration < 0.2  # < 200ms
    
    def test_concurrent_requests(self, client):
        def make_request():
            return client.get('/api/devices')
        
        with ThreadPoolExecutor(max_workers=50) as executor:
            futures = [executor.submit(make_request) for _ in range(100)]
            results = [f.result() for f in futures]
        
        success_count = sum(1 for r in results if r.status_code == 200)
        assert success_count >= 95  # 95% success rate
```

**Acceptance Criteria**:
- [ ] API response times meet targets
- [ ] Database queries optimized
- [ ] Concurrent load handled
- [ ] Performance benchmarks documented

**Time Estimate**: 3-4 hours

---

### TASK-078: Test Data Fixtures

**Description**: Create comprehensive test fixtures for all test types.

**Implementation**:
```python
# tests/fixtures/conftest.py
import pytest
from datetime import datetime

@pytest.fixture
def sample_device():
    return {
        'device_ip': '192.168.1.1',
        'hostname': 'router.local',
        'mac_address': '00:11:22:33:44:55',
        'vendor': 'Ubiquiti Networks',
        'os_detected': 'Linux 5.4',
        'device_type': 'router',
        'status': 'up',
        'first_seen': datetime.now(),
        'last_seen': datetime.now()
    }

@pytest.fixture
def sample_devices():
    # Return list of 50 devices
    pass

@pytest.fixture
def sample_scan_history():
    # Return scan history records
    pass
```

**Acceptance Criteria**:
- [ ] Fixtures for all data types
- [ ] Fixtures are reusable
- [ ] Factory functions for custom data
- [ ] Cleanup after tests

**Time Estimate**: 2-3 hours

---

### TASK-079: CI/CD Test Integration

**Description**: Integrate tests into GitHub Actions CI/CD pipeline.

**Implementation**:
```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'
      
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install -r requirements-dev.txt
      
      - name: Run unit tests
        run: pytest tests/unit -v --cov --cov-report=xml
      
      - name: Run integration tests
        run: pytest tests/integration -v
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

**Acceptance Criteria**:
- [ ] Tests run on every commit
- [ ] Coverage reports uploaded
- [ ] Failed tests block merges
- [ ] Test results visible in PRs

**Time Estimate**: 2-3 hours

---

### TASK-080: Test Documentation

**Description**: Document testing strategy, test execution, and contribution guidelines.

**Documentation**:
- `docs/testing/testing-strategy.md`: Overall approach
- `docs/testing/running-tests.md`: How to run tests locally
- `docs/testing/writing-tests.md`: Guidelines for contributors

**Acceptance Criteria**:
- [ ] Documentation is complete
- [ ] Examples provided
- [ ] Troubleshooting guide included

**Time Estimate**: 2-3 hours

---

### TASK-081: Test Coverage Goals

**Description**: Achieve and maintain >80% code coverage across all modules.

**Coverage Targets**:
- Scanner module: >90%
- Dashboard API: >85%
- Database layer: >90%
- Sync module: >80%
- Overall: >80%

**Acceptance Criteria**:
- [ ] Coverage targets met
- [ ] Coverage reports generated
- [ ] CI/CD enforces minimums

**Time Estimate**: Ongoing

---

### TASK-082: Security Testing

**Description**: Implement security-focused tests (SQL injection, XSS, auth bypass).

**Test Coverage**:
```python
# tests/security/test_security.py
import pytest

class TestSecurity:
    def test_sql_injection_prevention(self, client):
        # Attempt SQL injection
        response = client.get('/api/devices/192.168.1.1\' OR 1=1--')
        assert response.status_code in [400, 404]  # Not 200
    
    def test_input_validation(self, client):
        response = client.post('/api/devices/1.1.1.1/tags', json={
            'tags': ['<script>alert("xss")</script>']
        })
        # Verify tags are sanitized
        device = client.get('/api/devices/1.1.1.1').json
        assert '<script>' not in str(device['data']['device']['tags'])
```

**Acceptance Criteria**:
- [ ] Common vulnerabilities tested
- [ ] Input validation verified
- [ ] Security tests pass

**Time Estimate**: 3-4 hours

---

### TASK-083: Mock External Dependencies

**Description**: Create mocks for nmap, file system, and external APIs.

**Implementation**:
```python
# tests/mocks/nmap_mock.py
class MockNmap:
    def scan(self, hosts, arguments):
        return {
            'scan': {
                '192.168.1.1': {
                    'status': {'state': 'up'},
                    'tcp': {
                        80: {'state': 'open', 'name': 'http'},
                        443: {'state': 'open', 'name': 'https'}
                    }
                }
            }
        }
```

**Acceptance Criteria**:
- [ ] All external dependencies mockable
- [ ] Mocks are realistic
- [ ] Tests run without real dependencies

**Time Estimate**: 2-3 hours

---

### TASK-084: Test Automation & Reporting

**Description**: Automate test execution and generate reports.

**Acceptance Criteria**:
- [ ] Tests run automatically on commit
- [ ] HTML reports generated
- [ ] Slack/email notifications on failures
- [ ] Test trends tracked over time

**Time Estimate**: 2-3 hours

---

### TASK-085: Regression Test Suite

**Description**: Create regression test suite for critical functionality.

**Acceptance Criteria**:
- [ ] Core workflows have regression tests
- [ ] Regression tests run before releases
- [ ] Test suite is maintainable

**Time Estimate**: 2-3 hours

---

**Phase Acceptance Criteria**:
- All critical paths have test coverage
- Coverage >80% across all modules
- Tests run automatically in CI/CD
- Documentation is complete and accurate
- Performance benchmarks met

---

**Owner**: QA Team
**Review Date**: 2026-01-20
