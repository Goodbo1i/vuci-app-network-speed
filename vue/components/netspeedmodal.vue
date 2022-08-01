<template>
  <div>
    <a-modal :visible="visible" @cancel="handleCancel">
      <a-select
        v-model="value"
        :value="value"
        class="country-select"
        mode="default"
        :showSearch="true"
        style="width: 100%"
        placeholder="select one country"
        @change="handleChange"
      >
        <a-select-option
          v-for="availableCountry in availableCountries"
          :key="availableCountry"
          @click="getCountryServers(availableCountry)"
        >
          &nbsp;&nbsp;{{ availableCountry }}
        </a-select-option>
      </a-select>

      <div class="demo-infinite-container" :infinite-scroll-distance="10">
        <a-list
          :loading="!serverList[0] ? true : false"
          :class="!serverList[0] ? 'padding' : ''"
        >
          <h3>Please select a country</h3>
          <a-list-item
            v-for="(server, index) in serverList"
            :key="index"
            @click="changeSelectedServer(server)"
          >
            <a-list-item-meta :description="server.host">
              <a slot="title">{{ server.provider }}</a>
            </a-list-item-meta>
          </a-list-item>
        </a-list>
      </div>
      <template slot="footer">
        <a-button key="cancel" @click="handleCancel()"> Cancel </a-button>
        <a-button key="submit" type="primary" @click="handleOk()">
          Save
        </a-button>
      </template>
    </a-modal>
  </div>
</template>

<script>
/* eslint space-before-function-paren: ["error", "never"] */
export default {
  name: 'Configuaration',
  props: {
    availableCountries: Array,
    serverList: Array,
    visible: Boolean
  },
  data() {
    return {
      // value: 'select country'
    }
  },
  methods: {
    getCountryServers(selectedCountry) {
      this.value = selectedCountry

      this.$rpc
        .call('speedtest', 'get_server_list', { country: selectedCountry })
        .then((response) => {
          if (response.status === 'ok') {
            try {
              this.serverList = response.serverList.serverList
            } catch (e) {
              this.$message.error(e)
            }
          }
        })
        .catch((e) =>
          alert("Can't connect to server, check your internet connection")
        )
    },
    changeSelectedServer(server) {
      this.$emit('selected', server)

      console.log(this.value)

      this.$emit('closeModal')
      this.$emit('startTest')
    },
    handleCancel() {
      this.selectedServer = this.beforeModalServer
      this.$emit('closeModal')
    },
    handleOk() {
      this.$emit('closeModal')
    },
    handleChange(value) {
      console.log(`selected ${value}`)
    }
  }
}
</script>
<style>
#components-form-demo-validate-other .dropbox {
  height: 180px;
  line-height: 1.5;
}

.demo-infinite-container {
  border: 2px solid #e8e8e8;
  border-radius: 6px;
  overflow: auto;
  padding: 12px 24px;
  height: 500px;
}
.padding {
  padding: 200px 2px;
}
.demo-loading-container {
  position: absolute;
  bottom: 40px;
  width: 100%;
  text-align: center;
}
</style>
