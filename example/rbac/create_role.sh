#!/usr/bin/env bash

# 遇到非0退出码就报错
set -o errexit
# 访问到未定义的变量，产生错误并退出脚本
set -o nounset
# 使用管道时，任何一个命令失败时立即捕获并处理错误。默认情况下管道的退出状态，只取决于最后一个命令的退出状态
set -o pipefail

# 获取该项目的根目录
ETCD_OPERATOR_ROOT=$(dirname "${BASH_SOURCE}")/../..

# $0 是脚本名称
# basename 去除路径，只保留文件名
# $(...) 是命令替换的语法
print_usage() {
  echo "$(basename "$0") - Create Kubernetes RBAC role and role bindings for etcd-operator
Usage: $(basename "$0") [options...]
Options:
  --role-name=STRING         Name of ClusterRole to create
                               (default=\"etcd-operator\", environment variable: ROLE_NAME)
  --role-binding-name=STRING Name of ClusterRoleBinding to create
                               (default=\"etcd-operator\", environment variable: ROLE_BINDING_NAME)
  --namespace=STRING         namespace to create role and role binding in. Must already exist.
                               (default=\"default\", environment variable: NAMESPACE)
" >&2
}

# :- 是设置默认值，如果 ROLE_NAME 不存在时，ROLE_NAME的值为 etcd-operator
ROLE_NAME="${ROLE_NAME:-etcd-operator}"
# ROLE_BINDING_NAME 默认值: etcd-operator
ROLE_BINDING_NAME="${ROLE_BINDING_NAME:-etcd-operator}"
# NAMESPACE 默认值: default
NAMESPACE="${NAMESPACE:-default}"

# for 循环，用于遍历传递给脚本的命令行参数
# $@ 表示传递给脚本或函数的所有参数
for i in "$@"
do
case $i in
    # 判断传递的参数是否以 --role-name= 开头
    --role-name=*)
    # "${i#*=}" 从字符串开头删除最短匹配的字符串，直到遇见 = 停止
    # # 是处理字符串的标记，* 表示0个或者多个字符
    ROLE_NAME="${i#*=}"
    ;;
    # 判断传递的参数是否以 --role-binding-name= 开头
    --role-binding-name=*)
    ROLE_BINDING_NAME="${i#*=}"
    ;;
    # 判断传递的参数是否以 --namespace= 开头
    --namespace=*)
    NAMESPACE="${i#*=}"
    ;;
    # 打印帮助信息
    -h|--help)
      print_usage
      exit 0
    ;;
    # 打印帮助信息
    *)
      print_usage
      exit 1
    ;;
esac
done

# 当直接 ./create_role.sh 时，会打印如下信息
#Creating role with ROLE_NAME=etcd-operator, NAMESPACE=default
#clusterrole.rbac.authorization.k8s.io/etcd-operator created
#Creating role binding with ROLE_NAME=etcd-operator, ROLE_BINDING_NAME=etcd-operator, NAMESPACE=default
#clusterrolebinding.rbac.authorization.k8s.io/etcd-operator created
echo "Creating role with ROLE_NAME=${ROLE_NAME}, NAMESPACE=${NAMESPACE}"
sed -e "s/<ROLE_NAME>/${ROLE_NAME}/g" \
  -e "s/<NAMESPACE>/${NAMESPACE}/g" \
  "${ETCD_OPERATOR_ROOT}/example/rbac/cluster-role-template.yaml" | \
  # kubectl creat -f -  从标准输入中读取 yaml 并创建资源
  kubectl create -f -



echo "Creating role binding with ROLE_NAME=${ROLE_NAME}, ROLE_BINDING_NAME=${ROLE_BINDING_NAME}, NAMESPACE=${NAMESPACE}"
sed -e "s/<ROLE_NAME>/${ROLE_NAME}/g" \
  -e "s/<ROLE_BINDING_NAME>/${ROLE_BINDING_NAME}/g" \
  -e "s/<NAMESPACE>/${NAMESPACE}/g" \
  "${ETCD_OPERATOR_ROOT}/example/rbac/cluster-role-binding-template.yaml" | \
  kubectl create -f -
