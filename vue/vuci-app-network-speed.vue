<template>
  <div class="row">
    <div class="column left">
      <div class="button" >
        <a-button type="primary" size="large" @click="getBestServer()">
          Auto Best Select
        </a-button>
      </div>
      
      <a-select
      v-model="value"
      class="country-select"
      mode="default"
      :showSearch="true"
      style="width: 100%"
      placeholder="select one country"
      option-label-prop="label"
      >
          <a-select-option  v-for="(availableCountry) in availableCountries" :key="availableCountry">
              &nbsp;&nbsp;{{availableCountry}}
          </a-select-option>
      </a-select>

      <div
        class="demo-infinite-container"
        :infinite-scroll-disabled="busy"
        :infinite-scroll-distance="10"
      >
        <a-list>
          <a-list-item v-for="(server, index) in serverList" :key="index" @click="changeSelectedServer(server)">
            <a-list-item-meta :description="server.host">
              <a slot="title" >{{ server.provider }}</a>
            </a-list-item-meta>
          </a-list-item>
          <div v-if="loading && !busy" class="demo-loading-container">
            <a-spin />
          </div>
        </a-list>
      </div>
    </div>

    <div class="column right">
      <a-row >
        <a-col span="12" class="wrapper">
          <a-icon class="icon" type="user" :style="{fontSize: '55px'}"/>
          <span class="text"> 
            <p>{{userData.country}}</p> 
            <p>{{userData.ip}}</p> 
          </span>
        </a-col>
        <a-col span="12" class="wrapper">
          <a-icon type="global" :style="{fontSize: '55px'}"/>
          <span class="text"> 
            <p>{{selectedServer.provider}}</p>
            <p>{{selectedServer.city}}</p>
          </span>
        </a-col>
      </a-row>
        
      <gauge
        :heading="gauge.title"
        :min="0"
        :max="gauge.max"
        :value="gauge.value"
        :valueToExceedLimits="true"
        activeFill="gray"
        :inactiveFill="gauge.color"
        unit="Mbps"
        :unitOnArc="false"
        :pointerStrokeWidth="10"
        :pointerGap="2"
        
      />

      <div class="button">
        <a-button size="large" :title="isDisabled ? 'Wait for server to load' : ''"  @click="startSpeedTest()" :disabled="isDisabled">
          <h2>{{ loading ? 'Testing..' : 'Start Test' }}</h2>
        </a-button>
      </div>
      <div class="button">
        <a-row>
          <!-- <a-col span="8">
            <h4>0.111</h4>
            <h3>Latency</h3>
          </a-col> -->
          <a-col span="12">
            <h4>{{last_down}} Mb/s</h4>
            <h3>Download</h3>
          </a-col>
          <a-col span="12">
            <h4>{{last_up}} Mb/s</h4>
            <h3>Upload</h3>
          </a-col>
        </a-row>
      </div>
    </div>
  </div>
</template>
<script>
import infiniteScroll from 'vue-infinite-scroll';
import { Gauge } from '@chrisheanan/vue-gauge'

export default {
      components: {
        Gauge
      },
  data() {
      return {
        value: 'select country',
        loading: false,
        data: [],
        busy: false,
        toggle: false,
        gauge: {
          value: 0,
          title: '',
          color: 'green',
          max: 200
        },
        userData: {},
        bestServer: {},
        selectedServer: {},
        availableCountries: [],
        serverList: [],
        download_results: [],
        upload_results: [],
        last_down: 0,
        last_up: 0,
        isDisabled: true
      }
  },
  timers: {
    getScanResults: { time: 100, immediate: false, repeat: true }
  },
    methods: {
      startSpeedTest(){
        this.$rpc.call('speedtest','start_test',{"id": this.selectedServer.id})
          .then(response => {
            if(response.message == "Test Started"){
              try{
                this.$timer.start('getScanResults')
                this.loading = true
              }catch (e) {
                this.$message.error(e)
              }
            }
          })
      },
      getUserInfo () {
        this.$rpc.call('speedtest', 'get_user_info', { })
          .then(response => {
            if (response.ok) {
              try {
                this.userData = JSON.parse(JSON.stringify(response.data.user_data))
              } catch (e) {
                this.$message.error(e)
              }
            }
          })
      },
      getBestServer(){
        this.$rpc.call('speedtest','get_best_server', { })
          .then(response => {
            if (response.status) {
              try {
                this.bestServer = JSON.parse(JSON.stringify(response.best_server_info.best_server))
                this.selectedServer = this.bestServer
                this.isDisabled = false
              } catch (e) {
                this.$message.error(e)
              }
            }
          })
      },
      getAllCountries(){
        this.$rpc.call('speedtest','get_server_list', {})
          .then(response => {
            if(response.status == 'ok') {
              try {
                for (let i = 0; i < response.serverList.length; i++){
                  this.availableCountries[i] = response.serverList[i].country 
                }
                this.availableCountries = [...new Set(this.availableCountries)]
              } catch (e) {
                this.$message.error(e)
                }
            }
          })
      },
      getCountryServers(selectedCountry){
        this.$rpc.call('speedtest','get_server_list', {"country": selectedCountry})
        .then(response=> {
          if (response.status == 'ok') {
            try {
              this.serverList = response.serverList.serverList
            } catch(e){
              this.$message.error(e)
            }
          }
        })
      },
      getScanResults(){
        this.$rpc.call('speedtest','get_test_results', {})
          .then(response => {
            if(response.status == "ok"){
              try{
                this.download_results = response.download_results
                if(this.download_results.status == "working"){
                  this.gauge.value = this.download_results.download_speed
                } else if(this.download_results.status == "finished"){
                  this.last_down = this.download_results.download_speed.toFixed(3)
                  this.gauge.value = 0
                  this.upload_results = response.upload_results
                    if(this.upload_results.status == "working") {
                      this.gauge.value = this.upload_results.upload_speed
                    }
                    else if(this.upload_results.status == "finished"){
                      this.last_up = this.upload_results.upload_speed.toFixed(3)
                      this.gauge.value = 0
                      this.loading = false
                      this.$timer.stop("getScanResults")
                    }

                }

                if(this.download_results.status == "error"){
                  this.$message.error(this.download_results.message)
                  this.gauge.value = 0
                  this.loading = false
                  this.$timer.stop("getScanResults")
                } 
              } catch (error){
                this.$message.error(error)
                this.loading = false
              }
            }
            // else if(response.status == "error"){
            //       this.$message.error(response.message)
            //       this.$timer.stop("getScanResults")
            //       this.gauge.value = 0
            //       this.loading = false
            //     }
          })
      },
      changeSelectedServer(server){
        this.selectedServer.provider = server.provider
        this.selectedServer.city = server.city
      },
    },
  watch: {
    value(val) {
      console.log(`selected:`, val)
      this.getCountryServers(val)
    },
    userData(){
      console.log(this.userData.country)
      this.getCountryServers(this.userData.country)   

    }
  },
  mounted(){
    this.getAllCountries()
    this.getUserInfo()
    this.getBestServer()
  }
    
}
</script>

<style>
.centered {
  justify-content: center;
  align-items: center;
  height: 5vh;
}
.button {
  padding:10px;
  text-align: center;
}
.demo-infinite-container {
  border: 1px solid #e8e8e8;
  border-radius: 4px;
  overflow: auto;
  padding: 8px 24px;
  height: 500px;
}
.demo-loading-container {
  position: absolute;
  bottom: 40px;
  width: 100%;
  text-align: center;
}
.country-select {
  padding:10px;
}
.column {
  float: left;
  padding: 10px;
}

.left {
  width: 40%;
}

.right {
  width: 60%;
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
</style>