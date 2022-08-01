<template>
  <div class="center">
    <netspeedmodal
      :availableCountries="availableCountries"
      :serverList="serverList"
      :visible="visible"
      ref="netspeedmodal"
      @closeModal="toggleModalVision()"
      @selected="(val) => (selectedServer = val)"
      @startTest="startSpeedTest(1)"
      v-model="selectedServer"
    />
    <a-row>
      <a-col span="6" class="wrapper">
        <a-icon class="icon" type="user" :style="{ fontSize: '55px' }" />
        <span class="text">
          <p>{{ userData.country }}</p>
          <p>{{ userData.ip }}</p>
          <a-icon type="minus" v-if="!userData.country"></a-icon>
        </span>
      </a-col>
      <a-col span="6" class="wrapper">
        <a-icon type="global" :style="{ fontSize: '55px' }" />
        <span class="text">
          <p>{{ selectedServer.provider }}</p>
          <p>{{ selectedServer.city }}</p>
          <a-icon type="minus" v-if="!selectedServer.provider"></a-icon>
        </span>
      </a-col>
      <a-col span="6">
        <h4>{{ last_down }} Mb/s</h4>
        <h3>Download</h3>
      </a-col>
      <a-col span="6">
        <h4>{{ last_up }} Mb/s</h4>
        <h3>Upload</h3>
      </a-col>
    </a-row>

    <div class="progressBox">
      <span v-if="errorText">{{ errorText }}</span>
    </div>

    <gauge
      :heading="gauge.title"
      :min="0"
      :max="gauge.max"
      :value="gauge.value"
      :valueToExceedLimits="true"
      activeFill="gray"
      :inactiveFill="gauge.color"
      unit="Mbps"
      :unitOnArc="true"
      :pointerStrokeWidth="10"
      :pointerGap="2"
    />

    <div class="center">
      <a-row>
        <a-col span="12" class="wrapper">
          <a-button
            size="large"
            :title="isDisabled ? 'Wait for server to load' : ''"
            @click="startSpeedTest()"
            :disabled="isDisabled"
          >
            <h2>{{ loading ? 'Testing..' : 'Start Test' }}</h2>
          </a-button>
        </a-col>
        <a-col span="12">
          <a-button
            type="primary"
            size="large"
            @click="showModal(selectedServer)"
            :disabled="testInProgress"
            :title="testInProgress ? 'Wait for test to finish' : ''"
          >
            Select Server Manually
          </a-button>
        </a-col>
      </a-row>
    </div>
  </div>
</template>
<script>
/* eslint space-before-function-paren: ["error", "never"] */

// import infiniteScroll from 'vue-infinite-scroll'

import { Gauge } from '@chrisheanan/vue-gauge'
import netspeedmodal from './components/netspeedmodal.vue'

export default {
  components: {
    Gauge,
    netspeedmodal
  },
  data() {
    return {
      loading: false,
      data: [],
      toggle: false,
      gauge: {
        value: 0,
        title: '',
        color: '#05A4FF',
        max: 100
      },
      userData: {},
      selectedServer: {},
      availableCountries: [],
      serverList: [],
      download_results: [],
      upload_results: [],
      last_down: 0,
      last_up: 0,
      isDisabled: false,
      visible: false,
      beforeModalServer: {},
      testInProgress: false,
      errorText: ''
    }
  },
  timers: {
    getScanResults: { time: 200, immediate: false, repeat: true }
  },
  methods: {
    toggleModalVision() {
      this.visible = false
      console.log('Hello')
    },
    showModal(server) {
      this.beforeModalServer = server
      this.visible = true
    },
    startSpeedTest(num) {
      if (num !== 1) {
        this.userData = {}
        this.selectedServer = {}
      }

      this.last_down = 0
      this.last_up = 0
      if (!this.selectedServer.host) {
        this.getUserInfo()
        this.getBestServer()
        this.errorText = 'Finding Best Server'
      }
      this.$rpc
        .call('speedtest', 'start_test', { id: this.selectedServer.id })
        .then((response) => {
          if (response.message === 'Test Started') {
            try {
              this.$timer.start('getScanResults')
              this.loading = true
              this.testInProgress = true
            } catch (e) {
              this.errorText = e
            }
          }
        })
        .catch((e) => {
          this.errorText =
            "Can't connect to server, check your internet connection"
        })
    },
    getUserInfo() {
      this.$rpc.call('speedtest', 'get_user_info', {}).then((response) => {
        if (response.ok) {
          try {
            this.userData = JSON.parse(JSON.stringify(response.data.user_data))
          } catch (e) {
            this.errorText = e
          }
        }
      })
    },
    getBestServer() {
      this.$rpc.call('speedtest', 'get_best_server', {}).then((response) => {
        if (response.status) {
          try {
            this.selectedServer = JSON.parse(
              JSON.stringify(response.best_server_info.best_server)
            )
            this.isDisabled = false
            this.startSpeedTest(1)
          } catch (e) {
            this.errorText = e
          }
        }
      })
    },
    getAllCountries() {
      this.$rpc.call('speedtest', 'get_server_list', {}).then((response) => {
        if (response.status === 'ok') {
          try {
            for (let i = 0; i < response.serverList.length; i++) {
              this.availableCountries[i] = response.serverList[i].country
            }
            this.availableCountries = [...new Set(this.availableCountries)]
          } catch (e) {
            this.errorText = e
          }
        }
      })
    },
    getScanResults() {
      this.$rpc.call('speedtest', 'get_test_results', {}).then((response) => {
        if (response.status === 'ok') {
          try {
            this.download_results = response.download_results
            if (this.download_results.status === 'working') {
              this.gauge.value = this.download_results.download_speed
              this.errorText = 'Testing Download Speed'
            } else if (this.download_results.status === 'finished') {
              this.last_down = this.download_results.download_speed.toFixed(3)
              this.upload_results = response.upload_results
              if (this.upload_results.status === 'working') {
                this.errorText = 'Testing Upload Speed'
                this.gauge.value = this.upload_results.upload_speed
              } else if (this.upload_results.status === 'finished') {
                this.errorText = 'Speed test finished'
                this.last_up = this.upload_results.upload_speed.toFixed(3)
                this.gauge.value = 0
                this.loading = false
                this.testInProgress = false
                this.$timer.stop('getScanResults')
              }
            }

            if (this.download_results.status === 'error') {
              this.errorText = this.download_results.message
              this.gauge.value = 0
              this.loading = false
              this.testInProgress = false
              this.$timer.stop('getScanResults')
            }
            if (this.status === 'error') {
              this.errorText = this.download_results.message
              this.gauge.value = 0
              this.loading = false
              this.testInProgress = false
              this.$timer.stop('getScanResults')
            }
          } catch (e) {
            this.errorText = e
          }
        }
      })
    }
  },
  mounted() {
    this.getAllCountries()
  }
}
</script>
<style>
.button {
  padding: 10px;
  text-align: center;
}
.country-select {
  padding: 10px;
}

.text {
  margin: 10px;
}
.wrapper {
  display: flex;
  flex-direction: row;
  justify-content: center;
  align-items: center;
}
.center {
  padding: 5%;
  align-items: center;
  justify-content: center;
  text-align: center;
}
.progressBox {
  padding: 20px;
  width: 60%;
  font-size: 24px;
  font-family: 'Courier New', Courier, monospace;
  display: flex;
  justify-content: center;
  margin: auto;
}
</style>
