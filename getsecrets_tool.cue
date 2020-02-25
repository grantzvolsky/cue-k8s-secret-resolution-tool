// Copyright 2020 Grant Zvolsky
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package base

import("encoding/json")
import("strings")
import("tool/cli")
import("tool/exec")

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

//////////////////////////
// getsecrets command
//////////////////////////
command: getsecrets: {
  for secretIdx, evaluableSecret in evaluableSecrets {
    valueTasks: {
      for valueKey, valueCmd in evaluableSecret.values {
        "\(secretIdx)": "\(valueKey)": exec.Run & { cmd: valueCmd, stdout: string }
      }
    }
    "print-\(secretIdx)": cli.Print & {
      $after: valueTasks["\(secretIdx)"]
      k8sSecrets: "\(secretIdx)": Secret & {
        metadata: name: evaluableSecret.name
        if evaluableSecret.type =~ ".*" { // this guard is required due to a bug in cue evaluation order
          type: evaluableSecret.type
        }
        for valueKey, v in getsecrets.valueTasks["\(secretIdx)"] { data: "\(valueKey)": v.stdout }
      }

      text: strings.Join([json.Marshal(x) for x in k8sSecrets], "\n")
    }
  }
}

