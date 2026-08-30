# frozen_string_literal: true

#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Stand-ins for the vmware-vra objects the driver talks to.
#
# The driver is a thin layer over the vmware-vra gem: nearly every method
# either asks a Vra object something or hands it a request. A bare `double`
# answers whatever it is told to answer, so a suite built on them keeps passing
# after vmware-vra renames a method -- which is exactly the change most likely
# to break the driver. Everything here is a verifying double checked against
# the real class instead, so the specs fail when the gem moves underneath them.
#
# Each helper takes a hash of overrides so an example can say only what it
# cares about:
#
#     vra_deployment(status: "CREATE_FAILED", failed?: true)
module VraApi
  # A VM inside a deployment, as returned by Vra::Deployment#resources.
  #
  # @param overrides [Hash] stubs to replace the defaults with
  # @return [InstanceDouble<Vra::Resource>]
  def vra_resource(overrides = {})
    instance_double(
      Vra::Resource,
      {
        id: "res-1",
        deployment_id: "dep-1",
        name: "test-server",
        ip_address: "1.2.3.4",
        vm?: true,
      }.merge(overrides)
    )
  end

  # A deployment. This is also what Vra::DeploymentRequest#submit hands back,
  # which is why the driver waits on it and then asks it for its resources.
  #
  # @param overrides [Hash] stubs to replace the defaults with
  # @return [InstanceDouble<Vra::Deployment>]
  def vra_deployment(overrides = {})
    instance_double(
      Vra::Deployment,
      {
        id: "dep-1",
        name: "test-instance",
        status: "CREATE_SUCCESSFUL",
        failed?: false,
        completed?: true,
        completion_details: nil,
        refresh: nil,
        resources: [vra_resource],
      }.merge(overrides)
    )
  end

  # A request against a deployment, such as the destroy action.
  #
  # @param overrides [Hash] stubs to replace the defaults with
  # @return [InstanceDouble<Vra::Request>]
  def vra_request(overrides = {})
    instance_double(
      Vra::Request,
      {
        id: "req-1",
        status: "SUCCESSFUL",
        completed?: true,
        refresh: nil,
        details: nil,
      }.merge(overrides)
    )
  end

  # A catalog item, as returned by Vra::Catalog#fetch_catalog_items.
  #
  # @param overrides [Hash] stubs to replace the defaults with
  # @return [InstanceDouble<Vra::CatalogItem>]
  def vra_catalog_item(overrides = {})
    instance_double(
      Vra::CatalogItem,
      { id: "cat-1", name: "Ubuntu Server" }.merge(overrides)
    )
  end

  # An unsubmitted catalog request.
  #
  # @param overrides [Hash] stubs to replace the defaults with
  # @return [InstanceDouble<Vra::DeploymentRequest>]
  def vra_deployment_request(overrides = {})
    instance_double(
      Vra::DeploymentRequest,
      { submit: vra_deployment, set_parameters: nil }.merge(overrides)
    )
  end

  # A vRA API client, wired to a catalog and a deployments collection.
  #
  # @param catalog [InstanceDouble<Vra::Catalog>, nil]
  # @param deployments [InstanceDouble<Vra::Deployments>, nil]
  # @return [InstanceDouble<Vra::Client>]
  def vra_client(catalog: nil, deployments: nil)
    instance_double(
      Vra::Client,
      catalog:     catalog || instance_double(Vra::Catalog),
      deployments: deployments || instance_double(Vra::Deployments)
    )
  end
end
