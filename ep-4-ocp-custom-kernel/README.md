# Replace Kernel Package in OpenShift 4

Steps to replace the kernel package in OCP 4

1. Review the files in the current folder
   1. 70-edgeclass1-mc.yaml
   2. openshiftcustomkernel.conf
   3. openshiftcustomkernel.sh
   4. 75-edgeclass1-mc.yaml
   5. openshiftcustomkernel.path
   6. edgeclass1-mcp.yaml
   7. openshiftcustomkernel.service
2. Create the machine config pool object
```bash
oc create -f edgeclass1-mcp.yaml
```
3. 