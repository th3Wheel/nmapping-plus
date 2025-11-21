# Contributing to nMapping+

Thank you for your interest in contributing to nMapping+! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### Reporting Issues

Before creating an issue, please:

1. **Search existing issues** to avoid duplicates
2. **Use the appropriate template** (Bug Report or Feature Request)
3. **Provide detailed information** including environment details and steps to reproduce
4. **Sanitize sensitive information** such as IP addresses and network configurations

### Submitting Pull Requests

1. **Fork the repository** and create a feature branch
2. **Make your changes** following our coding standards
3. **Test thoroughly** in your environment
4. **Update documentation** as needed
5. **Submit a pull request** using the provided template

## 🔧 Development Setup

### Prerequisites

- **Proxmox VE 7.0+** for container testing
- **Python 3.9+** for development
- **Git** for version control
- **Shell environment** (Bash/Zsh) for script testing

### Local Development

```bash
# Clone your fork
git clone https://github.com/your-username/nmapping-plus.git
cd nmapping-plus

# Create development branch
git checkout -b feature/your-feature-name

# Set up Python environment
python3 -m venv venv
source venv/bin/activate
pip install -r dashboard/requirements.txt

# Install development dependencies
pip install pytest flake8 black isort pylint bandit safety
```

### Testing Your Changes

```bash
# Run code quality checks
black dashboard/
isort dashboard/
flake8 dashboard/
pylint dashboard/

# Run security checks
bandit -r dashboard/
safety check

# Test scripts (requires Proxmox environment)
shellcheck scripts/*.sh

# Test dashboard application
cd dashboard/
python dashboard_app.py --test-mode
```

## 📝 Coding Standards

### Python Code

- **Style**: Follow PEP 8 guidelines
- **Formatting**: Use Black with 88-character line length
- **Imports**: Use isort for import organization
- **Documentation**: Include docstrings for all functions and classes
- **Error Handling**: Implement proper exception handling
- **Security**: Follow OWASP guidelines for web applications

### Shell Scripts

- **Shebang**: Use `#!/bin/bash` for Bash scripts
- **Error Handling**: Set `set -euo pipefail` for robust error handling
- **Documentation**: Include function descriptions and usage examples
- **Validation**: Use shellcheck for script validation
- **Portability**: Ensure compatibility with target distributions

### Documentation

- **Markdown**: Use standard Markdown formatting
- **Structure**: Follow existing documentation structure
- **Links**: Verify all links are working
- **Examples**: Include practical examples and code snippets
- **Accuracy**: Ensure technical accuracy and currency

## 🏗️ Project Structure

### Directory Organization

```
nMapping+/
├── .github/                    # GitHub templates and workflows
│   ├── workflows/              # CI/CD pipelines
│   ├── templates/              # Issue and PR templates
│   └── copilot-config.yml      # Copilot configuration
├── dashboard/                  # Web dashboard application
│   ├── dashboard_app.py        # Main Flask application
│   ├── templates/              # HTML templates
│   ├── static/                 # CSS, JS, images
│   └── requirements.txt        # Python dependencies
├── docs/                       # Documentation
│   ├── deployment-guide.md     # Installation instructions
│   ├── architecture.md         # System design
│   └── api-reference.md        # API documentation
├── scripts/                    # Installation and utility scripts
│   ├── create_nmap_lxc.sh     # Container creation
│   ├── install_dashboard_enhanced.sh  # Dashboard setup
│   └── sync_dashboard.sh       # Data synchronization
├── README.md                   # Project overview
├── CHANGELOG.md                # Version history
├── LICENSE                     # MIT License
└── CONTRIBUTING.md             # This file
```

### Component Responsibilities

- **Scripts**: Container deployment and system setup
- **Dashboard**: Web interface and data visualization
- **Documentation**: User guides and technical reference
- **GitHub**: Templates, workflows, and project management

## 🧪 Testing Guidelines

### Test Categories

1. **Unit Tests**: Individual function testing
2. **Integration Tests**: Component interaction testing
3. **System Tests**: End-to-end functionality testing
4. **Security Tests**: Vulnerability and security testing
5. **Performance Tests**: Load and performance testing

### Test Environment

- **Isolation**: Use dedicated test environments
- **Data**: Use synthetic or anonymized test data
- **Networks**: Test with various network configurations
- **Containers**: Test both single and dual container setups

### Testing Checklist

- [ ] Fresh installation works correctly
- [ ] Upgrade from previous version succeeds
- [ ] All API endpoints function properly
- [ ] Dashboard loads and updates in real-time
- [ ] Scanner discovers devices correctly
- [ ] Git synchronization works between containers
- [ ] Security features function as expected
- [ ] Performance meets requirements

## 🔒 Security Guidelines

### Security Considerations

- **Sensitive Data**: Never commit passwords, keys, or sensitive network information
- **Input Validation**: Validate all user inputs
- **Authentication**: Implement proper authentication mechanisms
- **Authorization**: Ensure proper access controls
- **Encryption**: Use encryption for sensitive data storage and transmission
- **Logging**: Log security events appropriately

### Security Testing

- **Static Analysis**: Use bandit for Python security scanning
- **Dependency Scanning**: Use safety to check for vulnerable dependencies
- **Code Review**: Conduct security-focused code reviews
- **Penetration Testing**: Perform security testing on deployed systems

## 📋 Pull Request Process

### Before Submitting

1. **Branch**: Create a feature branch from `develop`
2. **Commits**: Use descriptive commit messages
3. **Tests**: Ensure all tests pass
4. **Documentation**: Update relevant documentation
5. **Changelog**: Add entry to CHANGELOG.md

### Pull Request Review

1. **Automated Checks**: All CI/CD checks must pass
2. **Code Review**: At least one maintainer review required
3. **Testing**: Functional testing by reviewers
4. **Security Review**: Security implications assessed
5. **Documentation Review**: Documentation accuracy verified

### Merge Criteria

- [ ] All automated checks pass
- [ ] Code review completed and approved
- [ ] Documentation updated
- [ ] No merge conflicts
- [ ] Changelog updated
- [ ] Security considerations addressed

## 🎯 Contribution Areas

### High Priority

- **Bug Fixes**: Critical and high-priority bugs
- **Security Enhancements**: Security improvements and patches
- **Documentation**: Missing or outdated documentation
- **Performance**: Performance optimization and scalability
- **Compatibility**: Support for additional platforms and versions

### Medium Priority

- **Features**: New functionality and enhancements
- **Integration**: Third-party tool integrations
- **User Experience**: Dashboard and interface improvements
- **Testing**: Additional test coverage and automation
- **Deployment**: Improved deployment options and automation

### Special Skills Needed

- **Network Engineering**: Deep networking knowledge for advanced features
- **Security Engineering**: Security expertise for hardening and compliance
- **DevOps**: Container orchestration and deployment automation
- **Frontend Development**: Dashboard and user interface enhancements
- **Documentation**: Technical writing and user experience documentation

## 📞 Communication

### Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and community discussion
- **Pull Requests**: Code review and technical discussion
- **Security Issues**: Email security concerns to security@nmapping-plus.org

### Communication Guidelines

- **Be Respectful**: Maintain professional and inclusive communication
- **Be Clear**: Provide clear and detailed information
- **Be Patient**: Allow time for community response
- **Be Constructive**: Focus on solutions and improvements

## 🎖️ Recognition

### Contributors

We recognize contributors in several ways:

- **CONTRIBUTORS.md**: Listed as project contributors
- **Release Notes**: Mentioned in release acknowledgments
- **GitHub Profile**: Contribution history and statistics
- **Community Recognition**: Highlighted in community discussions

### Maintainers

Maintainers are experienced contributors who:

- Review and merge pull requests
- Triage and manage issues
- Guide project direction and standards
- Mentor new contributors

## 📄 License

By contributing to nMapping+, you agree that your contributions will be licensed under the MIT License.

## 🆘 Getting Help

If you need help with contributing:

1. **Read the Documentation**: Start with the deployment guide and API reference
2. **Search Issues**: Look for similar questions or problems
3. **Ask Questions**: Create a GitHub Discussion for general questions
4. **Contact Maintainers**: Use GitHub mentions for specific technical questions

## 🙏 Thank You

Thank you for contributing to nMapping+! Your contributions help make network monitoring accessible and effective for everyone.

---

**Happy Contributing!** 🚀