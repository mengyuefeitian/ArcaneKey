const cloud = require('wx-server-sdk');
cloud.init({ env: cloud.DYNAMIC_CURRENT_ENV });
const nodemailer = require('nodemailer');

exports.main = async (event, context) => {
  const { type, content, contact, fileIds, userInfo } = event;

  const transporter = nodemailer.createTransport({
    host: process.env.MAIL_HOST,
    port: parseInt(process.env.MAIL_PORT || '465'),
    secure: true,
    auth: { user: process.env.MAIL_USER, pass: process.env.MAIL_PASS },
  });

  let htmlContent = `<h3>反馈类型: ${type}</h3><pre>${content}</pre>`;
  if (contact) htmlContent += `<p>联系方式: ${contact}</p>`;
  if (userInfo) htmlContent += `<p>用户: ${userInfo.name || ''}</p>`;
  if (fileIds && fileIds.length > 0) {
    htmlContent += `<p>附件数量: ${fileIds.length}（请在云控制台查看）</p>`;
  }

  await transporter.sendMail({
    from: process.env.MAIL_USER,
    to: 'mengyuefeitian@gmail.com',
    subject: `[玄钥][${type}]`,
    html: htmlContent,
  });

  const db = cloud.database();
  await db.collection('feedbacks').add({
    data: { type, content, contact, fileIds, userInfo, createdAt: db.serverDate() },
  });

  return { success: true };
};
