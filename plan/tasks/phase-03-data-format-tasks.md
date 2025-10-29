# Phase 3: Data Format & Validation - Detailed Tasks

**Phase**: 3 of 12  
**Name**: Data Format & Validation  
**Duration**: 3-4 days  
**Effort**: 24-30 person-hours  
**Dependencies**: Phase 2 (Scanner Core)

---

## Phase Overview

Establish formal data exchange contracts between scanner and dashboard components. Define and implement validation schemas, data transformation pipelines, and ensure data integrity throughout the system.

---

## TASK-020: Define Device Markdown Schema

**Priority**: 🔴 Critical  
**Effort**: 4 hours  
**Dependencies**: TASK-014 (Scanner implementation)

### Description

Create formal specification for device markdown files including frontmatter schema, content structure, and validation rules.

### Acceptance Criteria

- [ ] JSON Schema created for device frontmatter
- [ ] Markdown content structure documented
- [ ] Example files provided
- [ ] Validation rules defined
- [ ] Documentation complete

### Implementation Details

**Create**: `schema/device.schema.json`

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://nmapping.local/schemas/device.schema.json",
  "title": "Device Scan Result",
  "description": "Schema for nMapping+ device scan markdown files",
  "type": "object",
  "required": ["device_ip", "hostname", "scan_date", "scanner_version"],
  "properties": {
    "device_ip": {
      "type": "string",
      "format": "ipv4",
      "description": "IPv4 address of the device"
    },
    "hostname": {
      "type": "string",
      "description": "DNS hostname or PTR record"
    },
    "mac_address": {
      "type": "string",
      "pattern": "^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$",
      "description": "MAC address (EUI-48 format)"
    },
    "vendor": {
      "type": "string",
      "description": "Hardware vendor from MAC OUI lookup"
    },
    "os_detected": {
      "type": "string",
      "description": "Operating system detected by Nmap"
    },
    "os_confidence": {
      "type": "integer",
      "minimum": 0,
      "maximum": 100,
      "description": "OS detection confidence percentage"
    },
    "scan_date": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 timestamp of scan"
    },
    "scanner_version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+\\.\\d+$",
      "description": "nMapping+ scanner version"
    },
    "open_ports": {
      "type": "array",
      "items": {
        "type": "integer",
        "minimum": 1,
        "maximum": 65535
      },
      "description": "List of open TCP/UDP ports"
    },
    "services": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["port", "protocol", "service"],
        "properties": {
          "port": {"type": "integer"},
          "protocol": {"type": "string", "enum": ["tcp", "udp"]},
          "service": {"type": "string"},
          "version": {"type": "string"},
          "product": {"type": "string"}
        }
      }
    },
    "device_type": {
      "type": "string",
      "enum": ["server", "workstation", "router", "switch", "printer", "iot", "unknown"]
    },
    "tags": {
      "type": "array",
      "items": {"type": "string"}
    },
    "notes": {
      "type": "string"
    }
  }
}
```

**Create**: `schema/scan-summary.schema.json`

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://nmapping.local/schemas/scan-summary.schema.json",
  "title": "Scan Summary",
  "description": "Schema for network scan summary files",
  "type": "object",
  "required": ["scan_id", "scan_type", "start_time", "end_time", "subnet", "devices_found"],
  "properties": {
    "scan_id": {
      "type": "string",
      "format": "uuid"
    },
    "scan_type": {
      "type": "string",
      "enum": ["discovery", "port_scan", "service_scan", "full_scan"]
    },
    "start_time": {
      "type": "string",
      "format": "date-time"
    },
    "end_time": {
      "type": "string",
      "format": "date-time"
    },
    "subnet": {
      "type": "string",
      "pattern": "^(\\d{1,3}\\.){3}\\d{1,3}/\\d{1,2}$"
    },
    "devices_found": {
      "type": "integer",
      "minimum": 0
    },
    "devices_up": {
      "type": "integer",
      "minimum": 0
    },
    "devices_down": {
      "type": "integer",
      "minimum": 0
    },
    "new_devices": {
      "type": "integer",
      "minimum": 0
    },
    "changed_devices": {
      "type": "integer",
      "minimum": 0
    },
    "scanner_version": {
      "type": "string"
    }
  }
}
```

**Create**: `docs/architecture/data-format-specification.md`

Document must include:
- File naming conventions (`192.168.1.1.md`)
- Directory structure
- Frontmatter format (YAML)
- Content markdown structure
- Git repository organization
- Example files

### Testing

```bash
# Validate schema files
python3 -c "import json; json.load(open('schema/device.schema.json'))"

# Test validation with example
pip install jsonschema
python3 scripts/validate_device.py examples/device-example.md
```

---

## TASK-021: Implement Data Validation Module

**Priority**: 🔴 Critical  
**Effort**: 6 hours  
**Dependencies**: TASK-020 (Schema definition)

### Description

Create Python module for validating device markdown files against schemas, with detailed error reporting.

### Implementation Details

**Create**: `src/validation/validator.py`

```python
"""Data validation module for nMapping+ device files."""

import json
import yaml
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from jsonschema import validate, ValidationError, Draft7Validator
import frontmatter
import logging

logger = logging.getLogger(__name__)


class DeviceValidator:
    """Validates device markdown files against JSON schema."""
    
    def __init__(self, schema_dir: Path):
        """Initialize validator with schema directory."""
        self.schema_dir = Path(schema_dir)
        self.device_schema = self._load_schema('device.schema.json')
        self.summary_schema = self._load_schema('scan-summary.schema.json')
        
    def _load_schema(self, schema_file: str) -> Dict:
        """Load and parse JSON schema file."""
        schema_path = self.schema_dir / schema_file
        with open(schema_path, 'r') as f:
            return json.load(f)
    
    def validate_device_file(self, file_path: Path) -> Tuple[bool, List[str]]:
        """
        Validate a device markdown file.
        
        Returns:
            Tuple of (is_valid, error_messages)
        """
        errors = []
        
        try:
            # Parse frontmatter
            with open(file_path, 'r') as f:
                post = frontmatter.load(f)
                metadata = post.metadata
                content = post.content
            
            # Validate metadata against schema
            try:
                validate(instance=metadata, schema=self.device_schema)
            except ValidationError as e:
                errors.append(f"Schema validation failed: {e.message}")
                errors.append(f"Failed at path: {' -> '.join(str(p) for p in e.path)}")
                return False, errors
            
            # Additional validation rules
            errors.extend(self._validate_ip_format(metadata))
            errors.extend(self._validate_port_ranges(metadata))
            errors.extend(self._validate_content_structure(content))
            
            if errors:
                return False, errors
                
            logger.info(f"Validation passed for {file_path}")
            return True, []
            
        except Exception as e:
            errors.append(f"Failed to parse file: {str(e)}")
            return False, errors
    
    def _validate_ip_format(self, metadata: Dict) -> List[str]:
        """Validate IP address format and consistency."""
        errors = []
        ip = metadata.get('device_ip', '')
        
        # Check IP format
        parts = ip.split('.')
        if len(parts) != 4:
            errors.append(f"Invalid IP address format: {ip}")
        else:
            for part in parts:
                try:
                    num = int(part)
                    if not 0 <= num <= 255:
                        errors.append(f"IP octet out of range: {part}")
                except ValueError:
                    errors.append(f"Invalid IP octet: {part}")
        
        return errors
    
    def _validate_port_ranges(self, metadata: Dict) -> List[str]:
        """Validate port numbers are in valid range."""
        errors = []
        
        # Check open_ports list
        for port in metadata.get('open_ports', []):
            if not 1 <= port <= 65535:
                errors.append(f"Port out of range: {port}")
        
        # Check services array
        for service in metadata.get('services', []):
            port = service.get('port')
            if port and not 1 <= port <= 65535:
                errors.append(f"Service port out of range: {port}")
        
        return errors
    
    def _validate_content_structure(self, content: str) -> List[str]:
        """Validate markdown content structure."""
        errors = []
        
        # Check for required sections
        required_sections = ['## Device Information', '## Open Ports', '## Services']
        for section in required_sections:
            if section not in content:
                errors.append(f"Missing required section: {section}")
        
        return errors
    
    def validate_directory(self, directory: Path) -> Dict[str, Tuple[bool, List[str]]]:
        """
        Validate all markdown files in a directory.
        
        Returns:
            Dictionary mapping file paths to validation results
        """
        results = {}
        
        for md_file in directory.glob('**/*.md'):
            is_valid, errors = self.validate_device_file(md_file)
            results[str(md_file)] = (is_valid, errors)
        
        return results
    
    def get_validation_summary(self, results: Dict) -> Dict:
        """Generate summary statistics from validation results."""
        total = len(results)
        valid = sum(1 for is_valid, _ in results.values() if is_valid)
        invalid = total - valid
        
        return {
            'total_files': total,
            'valid_files': valid,
            'invalid_files': invalid,
            'validation_rate': (valid / total * 100) if total > 0 else 0
        }


# CLI for validation
if __name__ == '__main__':
    import sys
    import argparse
    
    parser = argparse.ArgumentParser(description='Validate nMapping+ device files')
    parser.add_argument('path', help='File or directory to validate')
    parser.add_argument('--schema-dir', default='schema', help='Schema directory path')
    args = parser.parse_args()
    
    validator = DeviceValidator(Path(args.schema_dir))
    path = Path(args.path)
    
    if path.is_file():
        is_valid, errors = validator.validate_device_file(path)
        if is_valid:
            print(f"✅ {path} is valid")
            sys.exit(0)
        else:
            print(f"❌ {path} validation failed:")
            for error in errors:
                print(f"  - {error}")
            sys.exit(1)
    elif path.is_dir():
        results = validator.validate_directory(path)
        summary = validator.get_validation_summary(results)
        
        print(f"\nValidation Summary:")
        print(f"  Total files: {summary['total_files']}")
        print(f"  Valid: {summary['valid_files']}")
        print(f"  Invalid: {summary['invalid_files']}")
        print(f"  Validation rate: {summary['validation_rate']:.1f}%")
        
        # Show errors
        for file_path, (is_valid, errors) in results.items():
            if not is_valid:
                print(f"\n❌ {file_path}:")
                for error in errors:
                    print(f"  - {error}")
        
        sys.exit(0 if summary['invalid_files'] == 0 else 1)
```

### Testing

```python
# tests/unit/test_validator.py
import pytest
from pathlib import Path
from src.validation.validator import DeviceValidator

def test_valid_device_file(tmp_path):
    """Test validation of valid device file."""
    # Create test file with valid frontmatter
    device_file = tmp_path / "192.168.1.1.md"
    device_file.write_text("""---
device_ip: 192.168.1.1
hostname: router.local
scan_date: 2025-10-19T10:00:00Z
scanner_version: 1.0.0
---

## Device Information
Router device
""")
    
    validator = DeviceValidator(Path('schema'))
    is_valid, errors = validator.validate_device_file(device_file)
    
    assert is_valid
    assert len(errors) == 0

def test_invalid_ip_address(tmp_path):
    """Test validation fails for invalid IP."""
    device_file = tmp_path / "invalid.md"
    device_file.write_text("""---
device_ip: 999.999.999.999
hostname: invalid.local
scan_date: 2025-10-19T10:00:00Z
scanner_version: 1.0.0
---

## Device Information
""")
    
    validator = DeviceValidator(Path('schema'))
    is_valid, errors = validator.validate_device_file(device_file)
    
    assert not is_valid
    assert any('IP' in error for error in errors)
```

---

## TASK-022: Create Example Device Files

**Priority**: 🟡 High  
**Effort**: 2 hours  
**Dependencies**: TASK-020

### Description

Create comprehensive example files demonstrating various device types and scan scenarios.

### Deliverables

**Create**: `examples/devices/router-192.168.1.1.md`  
**Create**: `examples/devices/server-192.168.1.10.md`  
**Create**: `examples/devices/printer-192.168.1.50.md`  
**Create**: `examples/devices/iot-192.168.1.100.md`  
**Create**: `examples/scans/discovery-2025-10-19.md`

Each file should be a complete, valid example following the schema.

---

## TASK-023: Implement Data Transformation Pipeline

**Priority**: 🔴 Critical  
**Effort**: 6 hours  
**Dependencies**: TASK-021

### Description

Create pipeline for transforming Nmap XML output to markdown format with proper frontmatter.

### Implementation Details

**Create**: `src/transform/nmap_to_markdown.py`

Key functions:
- `parse_nmap_xml(xml_file: Path) -> Dict`
- `generate_device_markdown(device_data: Dict) -> str`
- `write_device_file(device_data: Dict, output_dir: Path)`
- `transform_scan_results(xml_file: Path, output_dir: Path)`

---

## TASK-024: Add Frontmatter Parsing to Dashboard

**Priority**: 🔴 Critical  
**Effort**: 4 hours  
**Dependencies**: TASK-020, TASK-021

### Description

Update dashboard to parse and validate frontmatter from device markdown files.

### Implementation

Update `dashboard_app.py`:
- Import `python-frontmatter` library
- Parse YAML frontmatter when loading device files
- Validate data before inserting into database
- Handle malformed files gracefully
- Log validation errors

---

## TASK-025: Implement File Change Detection

**Priority**: 🟡 High  
**Effort**: 4 hours  
**Dependencies**: Phase 2

### Description

Create system for detecting changes in device markdown files for selective updates.

### Implementation Details

**Create**: `src/sync/change_detector.py`

Features:
- File hash computation
- Change detection logic
- New/modified/deleted file identification
- Git diff integration
- Change notification system

---

## TASK-026: Create Data Validation Tests

**Priority**: 🔴 Critical  
**Effort**: 4 hours  
**Dependencies**: TASK-021

### Description

Comprehensive test suite for data validation module.

### Test Coverage

- Valid device files (all fields)
- Minimal valid files (required fields only)
- Invalid IP addresses
- Invalid port numbers
- Missing required fields
- Malformed YAML
- Invalid enum values
- Boundary conditions

---

## TASK-027: Document Data Exchange Contract

**Priority**: 🟡 High  
**Effort**: 3 hours  
**Dependencies**: TASK-020

### Description

Create comprehensive documentation of data exchange between scanner and dashboard.

**Create**: `docs/architecture/data-contract.md`

Must include:
- Data flow diagram
- Format specifications
- Validation rules
- Error handling
- Version compatibility
- Migration procedures

---

## TASK-028: Add Schema Validation to Scanner

**Priority**: 🟡 High  
**Effort**: 3 hours  
**Dependencies**: TASK-021

### Description

Integrate validator into scanner to validate output before writing files.

Update `NmapScanner` class to:
- Validate data before generating markdown
- Log validation errors
- Retry on validation failures
- Provide detailed error messages

---

## TASK-029: Implement Version Compatibility Checks

**Priority**: 🟢 Medium  
**Effort**: 2 hours  
**Dependencies**: TASK-020

### Description

Add version checking to ensure scanner and dashboard data format compatibility.

Features:
- Schema version field in frontmatter
- Compatibility matrix
- Version mismatch warnings
- Upgrade path guidance

---

## TASK-030: Create Migration Tool for Existing Data

**Priority**: 🟢 Medium  
**Effort**: 4 hours  
**Dependencies**: TASK-021

### Description

Tool for migrating existing device files to new schema format.

**Create**: `scripts/migrate_data.py`

Features:
- Detect old format
- Transform to new format
- Preserve data integrity
- Backup before migration
- Rollback capability

---

## Phase 3 Completion Checklist

- [ ] TASK-020: Device markdown schema defined
- [ ] TASK-021: Data validation module implemented
- [ ] TASK-022: Example device files created
- [ ] TASK-023: Data transformation pipeline working
- [ ] TASK-024: Dashboard parses frontmatter
- [ ] TASK-025: File change detection implemented
- [ ] TASK-026: Validation tests passing
- [ ] TASK-027: Data contract documented
- [ ] TASK-028: Scanner validates output
- [ ] TASK-029: Version compatibility checks added
- [ ] TASK-030: Migration tool created

## Success Criteria

- ✅ JSON schemas validate correctly
- ✅ Validator catches all test cases
- ✅ Scanner generates valid markdown
- ✅ Dashboard parses all fields correctly
- ✅ Change detection works for git commits
- ✅ >90% test coverage for validation module
- ✅ Documentation complete and reviewed

---

**Phase Owner**: TBD  
**Review Date**: End of Phase 3  
**Next Phase**: Phase 4 - Scanner-Dashboard Synchronization
