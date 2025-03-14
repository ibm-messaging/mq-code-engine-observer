/**
 * Copyright 2024 IBM Corp.
 *
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

package configuration

type ceRegion struct {
	Region string `json:"region"`
}

type ceDetails struct {
	ApiKey       string     `json:"ce_apikey"`
	AuthEndpoint string     `json:"auth_endpoint"`
	ClientId     string     `json:"client_id"`
	ClientSecret string     `json:"client_secret"`
	Regions      []ceRegion `json:"regions"`
}

func (cer ceRegion) region() string {
	return cer.Region
}
