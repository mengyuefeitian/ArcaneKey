const cloud = require('wx-server-sdk');
cloud.init({ env: cloud.DYNAMIC_CURRENT_ENV });

const db = cloud.database();

exports.main = async (event, context) => {
  const wxContext = cloud.getWXContext();
  const { action, code } = event;

  // 获取 openid
  const openid = wxContext.OPENID;

  // 如果是获取手机号
  if (action === 'getPhoneNumber') {
    try {
      const result = await cloud.openapi.phonenumber.getPhoneNumber({ code });
      const phoneNumber = result.phoneInfo.purePhoneNumber;

      // 存储到 login 集合
      await db.collection('login').add({
        data: {
          openid,
          phoneNumber,
          createdAt: db.serverDate()
        }
      }).catch(() => {}); // 忽略重复添加错误

      return { success: true, openid, phoneNumber };
    } catch (err) {
      console.error('getPhoneNumber failed', err);
      return { success: false, openid, phoneNumber: '' };
    }
  }

  // 检查是否已登录
  try {
    const userRes = await db.collection('login').where({ openid }).get();
    if (userRes.data.length > 0) {
      return {
        success: true,
        openid,
        phoneNumber: userRes.data[0].phoneNumber || '',
        exists: true
      };
    }
  } catch (err) {
    console.error('Query login failed', err);
  }

  // 新用户
  return { success: true, openid, phoneNumber: '', exists: false };
};