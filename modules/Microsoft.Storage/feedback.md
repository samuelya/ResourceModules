# Notes

- Every 'base' parent must reference 'carml' children as you'd otherwise not be able to deploy any extension resources
- Extension resources cannot use resource/existing references (as the resources are deployed yet - or not in the same file). Hence we must use the 'old' resource type implementation which Bicep is throwing warnings about for anybody consuming the module(s)
  - Example: Microsoft.Storage/storageAccounts/providers/diagnosticSettings@2021-09-01

# Pro

- Resource Types can be updated & tested without any changes in other modules

# Con

- Extremely high effort in updating e.g. 'immutability policies' if we introduce a new parameter/property. Because we'd need all the following steps
  1. Update the 'immutability policies' base module, test it, open a PR, publish
  2. Update the 'containers' base module with a reference to the new referenced version, test it, open a PR, publish
  3. Update the 'containers' carml module with a reference to the new referenced version, test it, open a PR, publish
  4. Update the 'blobServices' base module with a reference to the new referenced version, test it, open a PR, publish
  5. Update the 'blobServices' carml module with a reference to the new referenced version, test it, open a PR, publish
  6. Update the 'storageAccount' base module with a reference to the new referenced version, test it, open a PR, publish
  7. Update the 'storageAccount' carml module with a reference to the new referenced version, test it, open a PR, publish
- Massive amount of additional test cases
- Leads to many Linter warnings (due to the resource type implementation)
  - ... unless we move all extension resources into their own sub-module
    - Which would however introduce even more deployments
    - Would make the individual module completely useless compared to the native resource type (e.g. Locks)
- Requires a strange mix of 'base' invoking CARML modules
- Bigger hazard of too long TemplateSpec names for some modules (like RSV) if we spell all resource types out
- Introduces additional deployments
