##### 使用ceph来提供动态存储

* 参考:https://www.jianshu.com/p/750a8fde377b?tdsourcetag=s_pctim_aiomsg
* 是否可删除pool
```
[mon] 
mon allow pool delete = true

重启mon
```