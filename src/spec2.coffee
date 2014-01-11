isVMRunning = ->
  switch @power_state
    when 'Paused', 'Running'
      true
    else
      false

isHostRunning = ->
  @power_state is 'Running'

module.export = ->

  {
    $set
    $sum
    $val
  } = @helpers

  # Defines which rule should be used for this item.
  #
  # Note: If the rule does not exists, a temporary item is created. FIXME
  @dispatch -> @genval.$type

  # Used to apply common definition to rules.
  @hook afterRule: ->
    # No need to worry about missing property, if the @key is
    # undefined the MappedCollection will throw.
    @key = -> @genkey

    unless $_.isObject @val
      throw new Error 'the value should be an object'

    # Injects various common definitions.
    @val.type = @name
    unless @singleton
      # This definition are for non singleton items only.
      @val.UUID = -> @genval.uuid
      @val.XAPIRef = -> @genval.$ref
      @val.poolRef = -> @genval.$pool

  # An item is equivalent to a rule but one and only one instance of
  # this rule is created without any generator.
  @item xo: ->
    @key = '00000000-0000-0000-0000-000000000000'
    @val = {

      # TODO: Maybe there should be high-level hosts: those who do not
      # belong to a pool.

      pools: $set {
        rule: 'pool'
      }

      $CPUs: $sum {
        rule: 'host'
        val: -> @val.CPUs.length
      }

      $running_VMs: $set {
        rule: 'VM'
        if: isVMRunning
      }

      $vCPUs: $sum {
        rule: 'VM'
        val: -> @val.CPUs.length
        if: isVMRunning
      }

      $memory: $sum {
        rule: 'host'
        val: -> @val.memory
        init: {
          usage: 0
          size: 0
        }
      }
    }

  @rule pool: ->
    @val = {
      name_label: -> @genval.name_label

      name_description: -> @genval.name_description

      tags: -> retrieveTags @key

      SRs: $set {
        rule: 'SR'
        bind: -> @val.$container
      }

      HA_enabled: -> @genval.ha_enabled

      hosts: $set {
        rule: 'host'
        bind: -> @genval.$pool
      }

      master: -> @val.master

      VMs: $set {
        rule: 'VM'
        bind: -> @val.$container
      }

      $running_hosts: $set {
        rule: 'host'
        bind: -> @genval.$pool
        if: isHostRunning
      }

      $running_VMs: $set {
        rule: 'VM'
        bind: -> @genval.$pool
        if: isVMRunning
      }

      $VMs: $set {
        rule: 'VM'
        bind: -> @genval.$pool
      }
    }

  @rule host: ->
    @val = {
      name_label: -> @genval.name_label

      name_description: -> @genval.name_description

      tags: -> retrieveTags @key

      address: -> @genval.address

      controller: $val {
        rule: 'VM-controller'
        bind: -> @genval.$container
      }

      CPUs: -> @genval.cpu_info

      enabled: -> @genval.enabled

      hostname: -> @genval.hostname

      iSCSI_name: -> @genval.other_config?.iscsi_iqn ? null

      memory: $sum {
        key: -> @genval.metrics
      }

      # TODO
      power_state: 'Running'

      # Local SRs are handled directly in `SR.$container`.
      SRs: $set {
        rule: 'SR'
        bind: -> @val.$container
      }

      # Local VMs are handled directly in `VM.$container`.
      VMs: $set {
        rule: 'VM'
        bind: -> @val.$container
      }

      $PBDs: -> @genval.PBDs

      $PIFs: $set {
        key: -> @genval.PIFs
      }

      $messages: $set {
        rule: 'message'
        bind: -> @genval.object
      }

      $tasks: $set {
        rule: 'task'
        bind: -> @val.$container
        if: -> @val.status is 'pending' or @val.status is 'cancelling'
      }

      $running_VMs: $set {
        rule: 'VM'
        bind: -> @val.$container
        if: isVMRunning
      }

      $vCPUs: $sum {
        rule: 'VM'
        bind: -> @val.$container
        if: isVMRunning
        val: -> @val.CPUs.number
      }
    }

  @rule VM: ->
    @val = {
      name_label: -> @genval.name_label

      name_description: -> @genval.name_description

      tags: -> retrieveTags @key

      address: {
        ip: $val {
          key: -> @genval.guest_metrics
          val: -> @val.networks
          default: null
        }
      }

      consoles: $set {
        key: -> @genval.consoles
      }

      # TODO: parses XML and converts it to an object.
      # @genval.other_config?.disks
      disks: [
        {
          device: '0'
          name_description: 'Created with Xen-Orchestra'
          size: 8589934592
          SR: null
        }
      ]

      memory: {
        usage: null
        size: $val {
          key: -> @genval.guest_metrics
          val: -> +@val.memory_actual
          default: +@genval.memory_dynamic_min
        }
      }

      $messages: $set {
        rule: 'message'
        bind: -> @genval.object
      }

      power_state: -> @genval.power_state

      CPUs: {
        number: $val {
          key: -> @genval.metrics
          val: -> +@genval.VCPUs_number

          # FIXME: must be evaluated in the context of the current object.
          if: -> @gen
        }
      }
    }
