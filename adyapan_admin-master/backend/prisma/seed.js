const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding Adyapan database...');

  // --- Create Schools ---
  const schoolsData = [
    { name: 'Adyapan Public School', principal: 'Dr. Amit Sen', location: 'Mumbai, Maharashtra' },
    { name: "St. Xavier's High School", principal: 'Fr. Sebastian S.J.', location: 'South Mumbai' },
    { name: 'Delhi Public School', principal: 'Mrs. Sudha Murthy', location: 'New Delhi' },
    { name: 'Ryan International School', principal: 'Mr. Rajesh Sharma', location: 'Pune, Maharashtra' },
    { name: 'Sharda Mandir High School', principal: 'Dr. Sunita Patil', location: 'Ahmedabad, Gujarat' },
  ];

  const schools = [];
  for (const s of schoolsData) {
    const school = await prisma.school.create({ data: s });
    schools.push(school);
    console.log(`  ✅ School: ${school.name}`);
  }

  // --- Create Teachers ---
  const teachersData = [
    { name: 'Rahul', uid: '12341', email: 'teacher@gmail.com', subject: 'Mathematics', syllabusCompletion: 72.5, classAttendance: 94.2, pendingDoubts: 1, mobile: '+91 98765 43210' },
    { name: 'Priya Patel', uid: '12342', email: 'priya@gmail.com', subject: 'Science - Physics', syllabusCompletion: 85.0, classAttendance: 95.5, pendingDoubts: 0, mobile: '+91 98765 43211' },
    { name: 'Amit Verma', uid: '12343', email: 'amit@gmail.com', subject: 'English', syllabusCompletion: 60.0, classAttendance: 91.0, pendingDoubts: 3, mobile: '+91 98765 43212' },
    { name: 'Sneha Rao', uid: '12344', email: 'sneha@gmail.com', subject: 'History', syllabusCompletion: 90.0, classAttendance: 96.8, pendingDoubts: 0, mobile: '+91 98765 43213' },
  ];

  for (const t of teachersData) {
    const teacher = await prisma.teacher.create({
      data: { ...t, schoolId: schools[0].id },
    });
    console.log(`  ✅ Teacher: ${teacher.name}`);
  }

  // --- Create Students ---
  const studentsData = [
    { name: 'Kapish Bagde', gradeClass: 'Grade 10-A', rollNo: '24', lessonsCompleted: 42, questsCompleted: 8, rank: '#12', attendancePercentage: 94.0, homeworkDue: 3, progressPercentChange: 12.0, fatherName: 'Mr. Rajesh Bagde', classTeacher: 'Mrs. Sharma', email: 'kapish.bagde@example.com', mobile: '+91 98000 12345', futureSkill: 'AI & Machine Learning' },
    { name: 'Aarav Mehta', gradeClass: 'Grade 10-A', rollNo: '01', lessonsCompleted: 38, questsCompleted: 6, rank: '#28', attendancePercentage: 91.5, homeworkDue: 1, progressPercentChange: 8.5, fatherName: 'Mr. Suresh Mehta', classTeacher: 'Mrs. Sharma', email: 'aarav.mehta@example.com', mobile: '+91 98000 12346', futureSkill: 'Robotics & IoT' },
    { name: 'Diya Sharma', gradeClass: 'Grade 9-B', rollNo: '12', lessonsCompleted: 45, questsCompleted: 10, rank: '#5', attendancePercentage: 96.2, homeworkDue: 0, progressPercentChange: 15.0, fatherName: 'Mr. Ramesh Sharma', classTeacher: 'Mr. Verma', email: 'diya.sharma@example.com', mobile: '+91 98000 12347', futureSkill: 'UI/UX Product Design' },
    { name: 'Rohan Gupta', gradeClass: 'Grade 10-B', rollNo: '18', lessonsCompleted: 30, questsCompleted: 4, rank: '#45', attendancePercentage: 88.0, homeworkDue: 5, progressPercentChange: 4.8, fatherName: 'Mr. Anil Gupta', classTeacher: 'Mrs. Rao', email: 'rohan.gupta@example.com', mobile: '+91 98000 12348', futureSkill: 'Game Development (Unity)' },
    { name: 'Ananya Iyer', gradeClass: 'Grade 9-A', rollNo: '07', lessonsCompleted: 41, questsCompleted: 7, rank: '#18', attendancePercentage: 93.4, homeworkDue: 2, progressPercentChange: 10.2, fatherName: 'Mr. Sunil Iyer', classTeacher: 'Ms. Iyer', email: 'ananya.iyer@example.com', mobile: '+91 98000 12349', futureSkill: 'Cybersecurity & Ethics' },
  ];

  for (const s of studentsData) {
    const student = await prisma.student.create({
      data: { ...s, schoolId: schools[0].id },
    });
    console.log(`  ✅ Student: ${student.name}`);
  }

  // --- Create Live Classes ---
  const liveClassesData = [
    { subject: 'Mathematics', class_: 'Grade 10-A', teacher: 'Rahul', time: '10:30 AM', status: 'Starts in 10 mins', isLive: false },
    { subject: 'Science - Physics', class_: 'Grade 9-B', teacher: 'Priya Patel', time: '12:00 PM', status: 'Scheduled', isLive: false },
    { subject: 'Mathematics Doubt Room', class_: 'Grade 10-A & B', teacher: 'Rahul & Amit', time: 'LIVE', status: '12 active students', isLive: true },
    { subject: 'English Grammar Masterclass', class_: 'Grade 8-C', teacher: 'Amit Verma', time: 'LIVE', status: '24 active students', isLive: true },
  ];

  for (const lc of liveClassesData) {
    await prisma.liveClass.create({ data: lc });
    console.log(`  ✅ Live Class: ${lc.subject}`);
  }

  // --- Create System Events ---
  const eventsData = [
    { title: 'New Material Uploaded', desc: 'Rahul uploaded "Chapter 3 - Circles Notes.pdf" for Grade 10-A', time: '5 mins ago', icon: 'pdf', color: 'red' },
    { title: 'Quest Accomplished', desc: 'Kapish Bagde achieved Rank #12 in "Algebra Quest"', time: '12 mins ago', icon: 'trophy', color: 'amber' },
    { title: 'Homework Assigned', desc: 'Amit Verma assigned homework "Daily Quest #8" to Grade 9', time: '45 mins ago', icon: 'assignment', color: 'blue' },
    { title: 'System Sync Successful', desc: 'All databases synced with Live DB Cloud', time: '1 hour ago', icon: 'sync', color: 'green' },
  ];

  for (const e of eventsData) {
    await prisma.systemEvent.create({ data: e });
    console.log(`  ✅ Event: ${e.title}`);
  }

  // --- Create Leave Requests ---
  const leavesData = [
    { teacherName: 'Amit Verma', subject: 'English', teacherUid: '12343', dates: '29th May - 30th May (2 Days)', reason: "Suffering from high fever and severe throat infection. Under doctor's advice.", status: 'Pending' },
    { teacherName: 'Priya Patel', subject: 'Science - Physics', teacherUid: '12342', dates: '1st June - 3rd June (3 Days)', reason: 'Family emergency in hometown. Need to travel immediately.', status: 'Pending' },
    { teacherName: 'Sneha Rao', subject: 'History', teacherUid: '12344', dates: '5th June (1 Day)', reason: 'Scheduled dental surgery appointment.', status: 'Approved' },
  ];

  for (const l of leavesData) {
    await prisma.leaveRequest.create({ data: l });
    console.log(`  ✅ Leave: ${l.teacherName}`);
  }

  console.log('\n🎉 Seeding complete! All data stored in TiDB.');
}

main()
  .catch((e) => {
    console.error('❌ Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
