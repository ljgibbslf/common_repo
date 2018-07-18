# 第五三六步 不就是调个 ESP8266 WiFi 模块，这个我擅长

为了让我们的设备在这个互联网，甚至万物互联的时代不那么孤单无聊，我们得给它加持上 WiFi 无线模块。无线模块选择的是物联网 WiFi 届的“网红”——ESP8266系列的 12S 模块，使用 AT 指令在模块中实现我们的业务逻辑。本文分享的是项目中，在 WiFi 方面遇到的问题，解决之道以及一些设计心得。



#### 从 PC 串口助手到单片机

当你走出新手村时，我们的故事也就开始了。

在新手村中你可能使用 TTL 转 USB 模块连接 WiFi ，在上位机调试助手中设置波特率为115200，勾选上添加新行，参照官方 AT指令示例，成功地建立起一个 TCP 透明传输。当你完成这份新手任务后，我们就将开始下一段征程——在单片机上使用 AT 指令与模块进行通信。

毫无疑问，官方 AT 指令 API 会是一路上可靠的帮手。笔者也希望本文同样能助你一臂之力。

当你掌握了单片机串口的用法后，那么离使用单片机与无线模块通信，不过就差一层窗户纸罢了。本文使用 STM32 HAL库函数为例，不同的单片机只需要替换相应的 API 或者寄存器操作即可。

首先用杜邦线（当然，如果你够秀的话，钥匙也可以）连接单片机串口的 TX/RX 引脚与无线模块的 RX/TX 引脚，请注意模块的串口使用的是 3.3V 电平，使用 5V 串口电平的单片机可能需要电平转换。（笔者没有尝试过 5V串口电平）

当你想发送某条 AT 指令时，比如 AT+RST 时，你只需要将这这几个字符放入串口发送缓冲区，并加上换行符 \r\n ，然后发送即可。



事情就这么简单么，是也不是，下面以 HAL 库举个栗子：

```c
extern  uint8_t   UWifi_Rec_Buffer[UWifi_REC_MAX_BYTES];   //WiFi 串口接收缓冲区
extern  uint16_t  UWifi_Rec_Point;                         //WiFi 串口接收缓冲区指针
extern  uint8_t   UWifi_Send_Buffer[UWifi_SEND_MAX_BYTES]; //WiFi 串口发送缓冲区
uint8_t           WifiRxBuf;							 

#define 		USART_WIFI				USART2	
#define 		HUART_WIFI 				huart2

void  UWifi_Send_String(uint8_t * pstr)
{
    uint16_t  strlength;

    memset(UWifi_Send_Buffer, '\0', UWifi_SEND_MAX_BYTES);
    strcpy((char*)UWifi_Send_Buffer,(char*)pstr);
    strlength = strlen((char*)UWifi_Send_Buffer);

    HAL_UART_Receive_IT(&HUART_WIFI,&WifiRxBuf,1);

    HAL_UART_Transmit_IT(&HUART_WIFI,UWifi_Send_Buffer,strlength);

}
```

这里使用 HAL USART库，对 WiFi 模块发送操作进行了函数封装，接收参数为待发送的字符串指针。函数中做了几件微小的操作：

1. 将发送缓冲区清空；
2. 将参数指针指向的字符串使用 strcpy 函数复制到发送缓冲区中（实际上这里给自己留了个雷，遇到以后再说）；
3. 开启接收中断；
4. 发送缓冲区中的数据



在上层应用中调用发送函数发送 AT 指令

```c
void ESP8266_Soft_Reset(void)
{
    WIFI_Send_String("AT+RST\r\n");
    Delay_ms(2000);
}
```

正如在串口助手中需要勾选发送新行一样，切记给指令后面跟上 \r\n 换行符。正如我在 格竹课堂 的某篇文章中提到的，在某些情况下，\r \n 回车 添加新行两者组合才表示换行。我在项目中，一开始没有搞懂这个问题，就导致 AT 指令发送一直失败。



至此，我们就完成了 AT 指令的发送，一般来说我们需要得到 AT 指令的回复来了解执行的结果。接收会把发送操作略微复杂，涉及串口接收中断。如果你还刚接触上述这些内容，你可以先一股脑地发送一堆指令，参照 AT 指令示例 建立起一个 TCP 透明传输，而暂时忽视接收回复。但请放心，本文后半部分仍会以 STM32 HAL库举例讲解接收操作。



#### 制订传输协议 KXJH-223 ：开心就好

接下来我们先制订一套传输协议，以知乎吹哔标准委员会为名，制订KXJH-223 基于IEEE 802.11 b/g/n 物联网 WiFi 中短消息传输协议，协议版本号： 223。本文不需要往下看了，都是 1000 页的 specification ...（编不下去了）

实际上我们的协议制订非常简单，目的也是为了方便发送接收端按照应用需求，简单，快速，准确地交换信息。使用在接收发送双方都在我们控制下的情况。如果需要接入诸如阿里云这样的标准代理服务器，可能需要使用标准协议诸如MQTT等。



这里我们制定的 KXJH-233 协议帧结构如下：



具体的帧结构因需求而异，既然是自订协议，那么最大的目标就是方便...

说到方便，在具体的 C 语言编程中，实现自订协议少不了使用灵活的结构体 + 共用体语法。

结构体大家可能还比较熟悉，共用体则会比较陌生。简单来说，共用体中的变量都从同一个内存地址开始存放。

```
typedef union
{
  uint8_t	   foo[4];
  uint8_t      bob;
  uint32_t     peter; 
}a;
```

共用体 a 中，数组 foo，变量 bob 和 peter 都从同一个内存地址开始存放。换句话说，修改 foo[0] = 1 ,那么 bob 也会被修改为 1 ，而 Peter 的情况会复杂些，一般来说，低 8 位也会被修改为 1。



接下来笔者结合自己的程序，来展现下使用结构体+共用体的便利

```c
#define 	START_BYTE			0x10
#define 	END_BYTE			0x20
#define 	MESS_LENG			16  //16 BYTE
#define		MESS_ID_LENG		3
#define		MESS_FLAG_LENG		5//5
#define		MESS_DATA_LENG		(MESS_LENG - MESS_FLAG_LENG - MESS_ID_LENG)
#define		DIR_SEND			0x1

typedef union
{
	uint8_t	message_Buffer[MESS_LENG];
	struWifiMess wifiMess;
}uniWifiMess;

typedef struct  
{
	uint8_t startByte;
	uint8_t	dir_Type;
	uint8_t	user_id[MESS_ID_LENG];//MESS_ID_LENG : 3
	uint8_t	data[MESS_DATA_LENG];//MESS_DATA_LENG : 8 
	uint8_t CRCByte;
	uint8_t res;
	uint8_t	endByte;
	BOOL	is_proc;
	BOOL	is_first_mess;
}struWifiMess;
```

在头文件 esp8266.h 中定义了协议结构体，共用体以及相关宏定义。

```
void ESP8266_Send(uint8_t * data,enumMessType type,struWifi* conf)
{

  uniWifiMess 	sedMess;
  uint8_t         data_crc;
  uint16_t		dev_id = 0x0001;
  sedMess.wifiMess.startByte = START_BYTE;
  sedMess.wifiMess.endByte = END_BYTE;
  sedMess.wifiMess.dir_Type = (DIR_SEND << 4) + type;	

  uint8_t uid = (conf->user_id & 0xFF) - 0x30; 
  sedMess.wifiMess.user_id[0] = uid;
  sedMess.wifiMess.user_id[1] = (uint8_t)(dev_id >> 8);
  sedMess.wifiMess.user_id[2] = dev_id & 0x00FF;

  data_crc = data_crc + sedMess.wifiMess.startByte + sedMess.wifiMess.startByte + sedMess.wifiMess.startByte
      + sedMess.wifiMess.user_id[0] + sedMess.wifiMess.user_id[1]+ sedMess.wifiMess.user_id[2];

  if(type == MESS_REPO )	
  {
      //TODO check length
      for(int i = 0;i < MESS_DATA_LENG;i++)
      {

          sedMess.wifiMess.data[i] = *data;
          data_crc += *data;
          data++;
      }
  }
  sedMess.wifiMess.CRCByte = data_crc;
  UWifi_Send_String_mess(sedMess.message_Buffer);
}
```

从发送函数可以看出来，当需要定义协议帧中某项参数时，可以使用结构体的形式，如：`sedMess.wifiMess.startByte = START_BYTE;` 但当发送整帧协议时，`UWifi_Send_String_mess(sedMess.message_Buffer);`参数接收的是 uint8_t 指针形式，此时传入的是数组。而共用体的存在，则使结构体和数组使用完全相同的内存地址，两者存储的内容完全相同。

未完待续 

#### 参考

本文从一篇网络上的文章中或得很多帮助，原始出处没有找到，作者记录了在电子设计竞赛中使用 WiFi 模块的经历，我会尽快搜索到具体出处。

#### 代码

本项目的所有源代码，工程，PCB设计都可以在本项目的开源库中获取，并可以遵循 BSD 协议自由地修改，分发。