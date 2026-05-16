// 云函数入口文件
const cloud = require('wx-server-sdk');

cloud.init({
  env: cloud.DYNAMIC_CURRENT_ENV,
});

// 微信支付配置（生产环境需要替换为真实商户配置）
const PAY_CONFIG = {
  // 商户号（需要从微信支付商户平台获取）
  mchId: 'YOUR_MCH_ID',
  // API密钥（需要从商户平台获取）
  apiSecret: 'YOUR_API_SECRET',
  // 商品名称
  body: '星枢令会员',
  // 订单金额（单位：分） - 19.90元 = 1990分
  totalFee: 1990,
};

/**
 * 创建支付订单
 *
 * 生产环境说明：
 * 1. 需要在微信支付商户平台申请商户号
 * 2. 需要配置API密钥和证书
 * 3. 需要在小程序后台关联商户号
 * 4. 需要配置支付回调URL
 *
 * 当前为演示模式，返回模拟支付参数
 */
exports.main = async (event, context) => {
  const wxContext = cloud.getWXContext();
  const openid = wxContext.OPENID;

  if (!openid) {
    return {
      success: false,
      errMsg: '无法获取用户openid',
    };
  }

  try {
    // 生成订单号
    const outTradeNo = `AK${Date.now()}${Math.random().toString(36).substr(2, 4)}`;

    // 演示模式：返回模拟支付参数
    // 生产环境需要调用微信支付统一下单API获取真实prepay_id
    const isDemo = PAY_CONFIG.mchId === 'YOUR_MCH_ID';

    if (isDemo) {
      // 演示模式：直接返回成功，前端模拟支付成功
      console.log('Demo mode: skipping real payment flow');
      return {
        success: true,
        isDemo: true,
        outTradeNo,
        openid,
        expiryDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(),
        message: '演示模式：支付已模拟成功',
      };
    }

    // 生产模式：调用微信支付API（需要真实商户配置）
    // const payment = require('tenpay');
    // const pay = new payment({
    //   appid: wxContext.APPID,
    //   mchid: PAY_CONFIG.mchId,
    //   partnerKey: PAY_CONFIG.apiSecret,
    //   notify_url: 'YOUR_NOTIFY_URL', // 支付回调地址
    // });
    //
    // const result = await pay.unifiedOrder({
    //   body: PAY_CONFIG.body,
    //   out_trade_no: outTradeNo,
    //   total_fee: PAY_CONFIG.totalFee,
    //   openid: openid,
    //   trade_type: 'JSAPI',
    // });
    //
    // // 生成前端支付参数
    // const paymentParams = pay.getPayParamsForJSAPI(result.prepay_id);
    //
    // // 存储订单信息到数据库
    // const db = cloud.database();
    // await db.collection('payment_orders').add({
    //   data: {
    //     outTradeNo,
    //     openid,
    //     totalFee: PAY_CONFIG.totalFee,
    //     status: 'pending',
    //     createdAt: db.serverDate(),
    //   },
    // });
    //
    // return {
    //   success: true,
    //   isDemo: false,
    //   paymentParams,
    //   outTradeNo,
    // };

    // 当前返回演示模式
    return {
      success: true,
      isDemo: true,
      outTradeNo,
      openid,
      expiryDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(),
      message: '当前为演示模式，需要配置商户信息才能使用真实支付',
    };

  } catch (err) {
    console.error('Create payment error:', err);
    return {
      success: false,
      errMsg: err.message || '创建订单失败',
    };
  }
};