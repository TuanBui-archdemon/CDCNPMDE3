using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.Linq;
using System.Security.Permissions;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Do_An_So3
{
    public partial class frm1 : Form
    {
        private int changeCount = 0;
        private const string tableName = "BANG_GIA_TRUC_TUYEN";
        private const string statusMessage = "Đã có {0} thay đổi.";
        //private SqlConnection connection = null;
        private SqlCommand command = null;
        private DataSet dataToWatch = null;
       
        public frm1()
        {
            InitializeComponent();
        }

        private void frm1_Load(object sender, EventArgs e)
        {
            cbLenh.SelectedIndex = 0;
            DateTime today = DateTime.Today;
            lbNgay.Text = today.ToString("dd/MM/yyyy");
            cbMuaBan.SelectedIndex = 0;
            txtSoLuong.Text = "100";
            dgv_BGTT.ReadOnly = true;
            Program.connection();
            if (CanRequestNotifications() == true)
                BatDau();
            else
                MessageBox.Show("Bạn chưa kích hoạt dịch vụ Broker", "Lỗi", MessageBoxButtons.OK);
            dgv_BGTT.Columns[0].Width = 65;
            
 
        }

    
        private bool CanRequestNotifications()
        {
            try
            {
                SqlClientPermission perm = new SqlClientPermission(PermissionState.Unrestricted);

                perm.Demand();
                return true;
            }
            catch (Exception ex)
            {
                return false;
            }
        }


        private string GetSQL()
        {
            return " SELECT MACP AS[MÃ CP], DM_GIA2 AS[Giá Mua 2], DM_KL2 AS[KLM 2], DM_GIA1 AS[Giá Mua 1], DM_KL1 AS[KLM 1], KL_GIA AS[Giá Khớp], "
                + " KL_KL AS[KL Khớp], DB_GIA1 AS[Giá Bán 1], DB_KL1 AS[KLB 1], DB_GIA2 AS[Giá Bán 2], DB_KL2 AS[KLB 2] " +
                " FROM dbo.BANG_GIA_TRUC_TUYEN ";
        }
        private void BatDau()
        {
            changeCount = 0;
            // Remove any existing dependency connection, then create a new one.
            SqlDependency.Stop(Program.connectionString);
            try
            {
                SqlDependency.Start(Program.connectionString);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "Loi", MessageBoxButtons.OK);
                return;
            }

            if (command == null)
                command = new SqlCommand(GetSQL(),Program.conn);

            if (dataToWatch == null)
                dataToWatch = new DataSet();
            GetData();
            //connection.Close();
            
        }
        private void GetData()
        {

            dataToWatch.Clear();

            // Make sure the command object does not already have
            // a notification object associated with it.

            command.Notification = null;

            // Create and bind the SqlDependency object
            // to the command object.

            SqlDependency dependency = new SqlDependency(command);
            dependency.OnChange += dependency_OnChange;

            using (SqlDataAdapter adapter = new SqlDataAdapter(command))
            {
                adapter.Fill(dataToWatch, tableName);

                this.dgv_BGTT.DataSource = dataToWatch;
                this.dgv_BGTT.DataMember = tableName;
                //doi mau
                this.dgv_BGTT.Columns["Giá Khớp"].DefaultCellStyle.ForeColor = Color.Green;
                this.dgv_BGTT.Columns["KL Khớp"].DefaultCellStyle.ForeColor = Color.Green;
            }
        }

        private void dependency_OnChange(object sender, SqlNotificationEventArgs e)
        {
            // This event will occur on a thread pool thread.
            // It is illegal to update the UI from a worker thread
            // The following code checks to see if it is safe update the UI.
            ISynchronizeInvoke i = (ISynchronizeInvoke)this;

            // If InvokeRequired returns True, the code is executing on a worker thread.
            if (i.InvokeRequired)
            {
                // Create a delegate to perform the thread switch
                OnChangeEventHandler tempDelegate = new OnChangeEventHandler(dependency_OnChange);

                object[] args = new[] { sender, e };

                // Marshal the data from the worker thread
                // to the UI thread.
                i.BeginInvoke(tempDelegate, args);

                return;
            }

            // Remove the handler since it's only good
            // for a single notification
            SqlDependency dependency = (SqlDependency)sender;

            dependency.OnChange -= dependency_OnChange;

            changeCount += 1;
            this.lbKQ.Text = string.Format(statusMessage, changeCount);

            // At this point, the code is executing on the
            // UI thread, so it is safe to update the UI.


            // Reload the dataset that's bound to the grid.
            GetData();
        }

        private void btLamLai_Click_1(object sender, EventArgs e)
        {
            cbLenh.SelectedIndex = 0;
            cbMuaBan.SelectedIndex = 0;
            txtMa.Text = "";
            txtGia.Text = "";
            txtSoLuong.Text = "100";
        }

        private void btMuaBan_Click_1(object sender, EventArgs e)
        {
            //bat khong cho de trong 
            if (txtMa.Text.Equals("") || txtGia.Text.Equals("") || txtSoLuong.Text.Equals(""))
            {
                MessageBox.Show("--->Không được để trống dữ liệu<---", string.Empty, MessageBoxButtons.OK);
                return;
            }
            
            DateTime today = DateTime.Today;
            
            /*
             String cmd = "DECLARE	@return_value int "
                    + " EXEC	@return_value = [dbo].[SP_KHOPLENH_LO] "
                    + "@macp = N'" + txtMa.Text.Trim()
                    + "',@Ngay =N'" + today.ToString("MM/dd/yyyy")
                    + "',@LoaiGD='" + (cbMuaBan.SelectedIndex == 0 ? "M" : "B")
                    + "',@soluongMB=" + txtSoLuong.Text.Trim()
                    + ",@giadatMB=" + txtGia.Text.Trim();
                ;
            Program.ExecSqlDataTable(cmd); //chay lenh*/

            String ngay = today.ToString("yyyyMMdd");
            Program.ExecSP_KHOPLENH_LO(txtMa.Text.Trim(), ngay, (cbMuaBan.SelectedIndex == 0 ? "M" : "B"), txtSoLuong.Text.Trim(), txtGia.Text.Trim());
            MessageBox.Show("--->Giao Dịch Thành Công<---", string.Empty, MessageBoxButtons.OK);
            btLamLai_Click_1(sender, e);
        }
        //khong cho nhap chu
        //private void txtGia_TextChanged(object sender, EventArgs e)
        //{
        //    if (System.Text.RegularExpressions.Regex.IsMatch(txtGia.Text, "  ^ [0-9]"))
        //    {
        //        txtGia.Text = "";
        //    }
        //}

        //private void txtSoLuong_TextChanged(object sender, EventArgs e)
        //{
        //    if (System.Text.RegularExpressions.Regex.IsMatch(txtSoLuong.Text, "  ^ [0-9]"))
        //    {
        //        txtSoLuong.Text = "";
        //    }
        //}

        private void txtGia_TextChanged_1(object sender, EventArgs e)
        {
            if (System.Text.RegularExpressions.Regex.IsMatch(txtGia.Text, "  ^ [0-9]"))
            {
                txtGia.Text = "";
            }
        }

        private void cbMuaBan_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (cbMuaBan.SelectedIndex == 0)
            {
                btMuaBan.Text = "Mua";
            }
            if (cbMuaBan.SelectedIndex == 1) btMuaBan.Text = "Bán";
        }

        private void txtSoLuong_TextChanged_1(object sender, EventArgs e)
        {

        }

        private void txtSoLuong_KeyPress(object sender, KeyPressEventArgs e)
        {
            if (!char.IsControl(e.KeyChar) && !char.IsDigit(e.KeyChar) && (e.KeyChar != '.'))
            {
                e.Handled = true;
            }
        }

        private void txtGia_KeyPress(object sender, KeyPressEventArgs e)
        {
            if (!char.IsControl(e.KeyChar) && !char.IsDigit(e.KeyChar) && (e.KeyChar != '.'))
            {
                e.Handled = true;
            }
        }
    }
}
