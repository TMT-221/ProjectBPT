export function portFromEnvironment(env=process.env){
 const value=env.LABTRACK_PORT??'4173';
 if(!/^\d+$/.test(String(value)))throw new Error('LABTRACK_PORT phải từ 1024 đến 65535.');
 const port=Number(value);
 if(!Number.isInteger(port)||port<1024||port>65535)throw new Error('LABTRACK_PORT phải từ 1024 đến 65535.');
 return port;
}

// This is operator configuration, never a value supplied by proxy request headers.
export function validatePublicOrigin(value){
 if(typeof value!=='string'||!value||value.trim()!==value)throw new Error('LABTRACK_PUBLIC_ORIGIN phải là một HTTPS origin hợp lệ.');
 let url;
 try{url=new URL(value);}catch{throw new Error('LABTRACK_PUBLIC_ORIGIN phải là một HTTPS origin hợp lệ.');}
 if(url.protocol!=='https:'||url.username||url.password||url.pathname!=='/'||url.search||url.hash||value!==url.origin)
  throw new Error('LABTRACK_PUBLIC_ORIGIN phải là HTTPS origin chuẩn, không có đường dẫn, thông tin đăng nhập, query hoặc fragment.');
 return url.origin;
}

export function publicOriginFromEnvironment(env=process.env,port=portFromEnvironment(env)){
 if(!Number.isInteger(port)||port<1024||port>65535)throw new Error('LABTRACK_PORT phải từ 1024 đến 65535.');
 if(env.LABTRACK_PUBLIC_ORIGIN!==undefined)return validatePublicOrigin(env.LABTRACK_PUBLIC_ORIGIN);
 if(env.CODESPACES!=='true')return undefined;
 const name=env.CODESPACE_NAME,domain=env.GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN;
 const label=/^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$/;
 const labels=typeof domain==='string'?domain.split('.'):[];
 if(typeof name!=='string'||name.length>63||!label.test(name)||labels.length<2||domain.length>253||labels.some(part=>part.length>63||!label.test(part)))
  throw new Error('Codespaces cần CODESPACE_NAME và GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN hợp lệ.');
 if(`${name}-${port}`.length>63)throw new Error('Tên Codespace và cổng vượt giới hạn tên máy chủ.');
 return validatePublicOrigin(`https://${name}-${port}.${domain}`);
}
