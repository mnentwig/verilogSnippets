:: maps current directory to f:
:: will not work if run as administrator!
@echo "removing old mapping (error message is expected if not mapped)"
@subst f: /D
@subst f: "%~dp0"
@echo "f drive is now mapped to this directory"
@timeout 3