<template>
  <div class="center">
    <netspeedmodal
      :availableCountries="availableCountries"
      :visible="visible"
      ref="netspeedmodal"
      @closeModal="visible = false"
      @selected="(val) => (selectedServer = val)"
      @startTest="startSpeedTest('2')"
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
      <span v-if="textBox">{{ textBox }}</span>
    </div>

    <gauge
      :min="0"
      :max="gauge.max"
      :value="gauge.value"
      :valueToExceedLimits="true"
      activeFill="gray"
      :dp="2"
      :inactiveFill="gauge.color"
      unit="Mbps"
      :unitOnArc="true"
      :pointerStrokeWidth="10"
      :pointerGap="2"
    />

    <div class="center">
      <a-row>
        <a-col span="12" class="wrapper">
          <a-button size="large" @click="startSpeedTest()">
            <h2>{{ testInProgress ? 'Testing..' : 'Start Test' }}</h2>
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
        color: '#05A4FF',
        max: 100
      },
      userData: {},
      selectedServer: {},
      availableCountries: [],
      serverList: [],
      results: [],
      last_down: 0,
      last_up: 0,
      visible: false,
      beforeModalServer: {},
      testInProgress: false,
      textBox: ''
    }
  },
  timers: {
    // getDownloadResults: { time: 200, immediate: false, repeat: true },
    getTestResults: { time: 200, immediate: false, repeat: true }
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
      if (num !== '1' && num !== '2') {
        this.userData = {}
        this.selectedServer = {}
      }
      if (num === '2') this.userData = {}

      this.last_down = 0
      this.last_up = 0
      if (!this.selectedServer.host) {
        this.textBox = 'Finding Best Server'
        this.getUserInfo()
        this.getBestServer()
      }
      this.$rpc
        .call('speedtest', 'start_test', { id: this.selectedServer.id })
        .then((response) => {
          if (response.message === 'Test Started') {
            try {
              this.$timer.start('getTestResults')
              this.loading = true
              this.testInProgress = true
            } catch (e) {
              this.textBox = e
            }
          }
        })
        .catch((e) => {
          this.errorText =
            "Can't connect to server, check your internet connection"
        })
    },
    getUserInfo() {
      this.$rpc
        .call('speedtest', 'get_user_info', {})
        .then((response) => {
          if (response.ok) {
            try {
              this.userData = JSON.parse(
                JSON.stringify(response.data.user_data)
              )
            } catch (e) {
              this.textBox = e
            }
          }
        })
        .catch(() => {
          this.textBox = "Can't get info user, check internet connection"
        })
    },
    getBestServer() {
      this.$rpc
        .call('speedtest', 'get_best_server', {})
        .then((response) => {
          if (response.status) {
            try {
              this.selectedServer = JSON.parse(
                JSON.stringify(response.best_server_info.best_server)
              )
              this.startSpeedTest('1')
            } catch (e) {
              this.textBox = e
            }
          }
        })
        .catch(() => {
          this.textBox =
            "Can't get connect to server list, check internet connection"
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
            this.textBox = e
          }
        }
      })
    },
    getTestResults() {
      this.$rpc.call('speedtest', 'get_test_results', {}).then((response) => {
        if (response.status === 'ok') {
          try {
            if (this.last_down <= 0) {
              this.results = response.download_results
              this.getDownloadResults()
            } else if (this.last_down > 0) {
              this.results = response.upload_results
              this.getUploadResults()
            }
          } catch (e) {
            this.sendToTextBox = e
          }
        }
      })
    },
    getDownloadResults() {
      switch (this.results.status) {
        case 'working':
          this.gauge.value = this.results.download_speed
          this.textBox = 'Testing Download Speed'
          break
        case 'finished':
          this.last_down = this.results.download_speed.toFixed(3)
          this.sendToTextBox('Starting Upload Test')
          setTimeout(() => this.$timer.start('getTestResults'), 1000)
          break
        default:
          this.sendToTextBox(this.results.message)
      }
    },
    getUploadResults() {
      switch (this.results.status) {
        case 'working':
          this.gauge.value = this.results.upload_speed
          this.textBox = 'Testing Upload Speed'
          break
        case 'finished':
          this.last_up = this.results.upload_speed.toFixed(3)
          this.sendToTextBox('Test Finished')
          break
        default:
          this.sendToTextBox(this.results.message)
      }
    },
    sendToTextBox(text) {
      this.gauge.value = 0
      this.testInProgress = false
      this.textBox = text
      this.$timer.stop('getTestResults')
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
