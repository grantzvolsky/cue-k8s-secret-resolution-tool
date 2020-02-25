<!--
 Copyright 2020 Grant Zvolsky

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
-->

# Cuelang k8s secret resolution tool

Define secrets as part of your configuration and have them resolved by [cue](https://cuelang.org/).

<!--
TODO `run example in websecute` button
-->

## Example configuration

```
//////////////////////////
// Example basic schema
//////////////////////////
EvaluableSecret:: {
  name: string
  type?: string
  values: [string]: string | [string, ...string]
}

Secret:: {
  apiVersion: "v1"
  kind: "Secret"
  metadata: name: string
  data: [string]: string
  type: string | *"Opaque"
}

//////////////////////////
// Example data
//////////////////////////
evaluableSecrets: [...EvaluableSecret]
evaluableSecrets: [
  {
    name: "k8s-secret-1"
    values: "hello": "echo world"
    values: "some-other-secret": "printf test"
  },
  {
    name: "k8s-docker-config"
    type: "kubernetes.io/dockerconfigjson"
    values: ".dockerconfigjson": ["sh", "-c", "printf test | base64 -w0 | base64 -d"]
  }
]
```

The configuration above yields the NDJSON below upon running `cue getsecrets`.

```
{
  "type": "kubernetes.io/dockerconfigjson",
  "apiVersion": "v1",
  "kind": "Secret",
  "metadata": {
    "name": "k8s-docker-config"
  },
  "data": {
    ".dockerconfigjson": "test"
  }
}
{
  "type": "Opaque",
  "apiVersion": "v1",
  "kind": "Secret",
  "metadata": {
    "name": "k8s-secret-1"
  },
  "data": {
    "hello": "world\n",
    "some-other-secret": "test"
  }
}
```
