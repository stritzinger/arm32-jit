.PHONY: vuw
vuw:
	vagrant up --provider=vmware_desktop

.PHONY: vub
vub:
	vagrant up --provider=virtualbox
